//
//  AZXMonthHIstoryViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/11.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXMonthHIstoryViewController.h"
#import "AZXAllHistoryTableViewCell.h"
#import "AppDelegate.h"
#import "Account.h"
#import "AZXAccountViewController.h"
#import <CoreData/CoreData.h>

@interface AZXMonthHIstoryViewController () <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *TotalMoneyLabel;

@property (weak, nonatomic) IBOutlet UILabel *remainMoneyLabel;

@property (weak, nonatomic) IBOutlet UITableView *dayTableView;

@property (strong, nonatomic) NSArray *dataArray; // 储存fetch来的当前月份的Account

@property (strong, nonatomic) NSMutableArray *dayIncome; // 每天的收入金额

@property (strong, nonatomic) NSMutableArray *dayExpense; // 每天的支出金额


@property (nonatomic, assign) NSInteger totalIncome; // 总收入

@property (nonatomic, assign) NSInteger totalExpense; // 总支出

@property (strong, nonatomic) NSArray *uniqueDateArray; // 储存不重复月份的数组

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation AZXMonthHIstoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dayTableView.dataSource = self;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    // 数组的初始化
    self.dayIncome = [NSMutableArray array];
    self.dayExpense = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = self.date;
    
    [self fetchData];
    
    [self filterUniqueDate];
    
    [self calculateDayMoney];

    [self setTotalLabel];

    [self.dayTableView reloadData];
}

- (void)fetchData {
    // 取得当前月份的account
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@", self.date]];
    
    NSError *error = nil;
    self.dataArray = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];

}

- (void)filterUniqueDate {
    NSMutableArray *dateArray = [NSMutableArray array];
    
    for (Account *account in self.dataArray) {
        [dateArray addObject:account.date];
    }
    
    NSSet *set = [NSSet setWithArray:[dateArray copy]];
    
    NSArray *SortDesc = @[[[NSSortDescriptor alloc] initWithKey:nil ascending:YES]];
    
    self.uniqueDateArray = [set sortedArrayUsingDescriptors:SortDesc];
}

- (void)calculateDayMoney {
    // 防止叠加，暂存数组，暂存总额
    NSInteger tmpTotalIncome = 0;
    NSInteger tmpTotalExpense = 0;

    NSMutableArray *tmpDayIncome = [NSMutableArray array];
    NSMutableArray *tmpDayExpense = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.uniqueDateArray.count; i++) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.uniqueDateArray[i]]];
        
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];

        NSInteger income = 0;
        NSInteger expense = 0;
        
        for (Account *account in results) {
            if ([account.incomeType isEqualToString:@"income"]) {
                income += [account.money integerValue];
            } else {
                expense += [account.money integerValue];
            }
        }
        
        tmpTotalIncome += income;
        tmpTotalExpense += expense;
        
        [tmpDayIncome addObject:[NSString stringWithFormat:@"%ld", (long)income]];
        [tmpDayExpense addObject:[NSString stringWithFormat:@"%ld", (long)expense]];
    }
    
    self.totalIncome = tmpTotalIncome;
    self.totalExpense = tmpTotalExpense;

    self.dayIncome = tmpDayIncome;
    self.dayExpense = tmpDayExpense;
}

- (void)setTotalLabel {
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"本月收入: %ld  本月支出: %ld", (long)self.totalIncome, (long)self.totalExpense]];
    
    // 示意图: 总收入: xxx(不限长度)  总支出: xxx(不限长度)
    NSString *incomeString = [NSString stringWithFormat:@"%ld", (long)self.totalIncome];
    NSString *expenseString = [NSString stringWithFormat:@"%ld", (long)self.totalExpense];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 5)];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(6, incomeString.length)];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(6 + incomeString.length + 2, 5)];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(6 + incomeString.length + 2 + 6, expenseString.length)];
    
    [self.TotalMoneyLabel setAttributedText:mutString];
    
    
    // 计算结余
    NSInteger remainMoney = self.totalIncome - self.totalExpense;
    
    self.remainMoneyLabel.text = [NSString stringWithFormat:@"结余: %ld", (long)remainMoney];
    
}


#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueDateArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AZXAllHistoryTableViewCell *cell = [self.dayTableView dequeueReusableCellWithIdentifier:@"dayAccountCell" forIndexPath:indexPath];
    
    NSString *fullDate = self.uniqueDateArray[indexPath.row];
    cell.date.text = [fullDate substringFromIndex:5];
    
    NSMutableAttributedString * mutString = [self configMoneyLabelWithIndexPath:indexPath];
    
    [cell.money setAttributedText:mutString];
    
    return cell;
}

- (NSMutableAttributedString *)configMoneyLabelWithIndexPath:(NSIndexPath *)indexPath {
    // 收入金额
    NSString  *income = self.dayIncome[indexPath.row];
    
    NSString *incomeString = [@"收入: " stringByAppendingString:income];
    
    // 为了排版，固定金额数目为7位，不足补空格
    for (NSInteger i = income.length; i < 7; i++) {
        incomeString = [incomeString stringByAppendingString:@" "];
    }
    
    // 支出金额(前留一空格)
    NSString *expense = self.dayExpense[indexPath.row];
    NSString *expenseString = [@" 支出: " stringByAppendingString:expense];
    
    // 排版
    for (NSInteger i = expense.length; i < 7; i++) {
        expenseString = [expenseString stringByAppendingString:@" "];
    }
    
    // 合并两个字符串
    NSString *moneyString = [incomeString stringByAppendingString:expenseString];
    
    // 设置文本不同颜色
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:moneyString];
    
    // 示意图: 收入: xxxxxxx 支出: xxxxxxx
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 3)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(4, 7)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(12, 3)];
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(16, 7)];
    
    return mutString;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDayDetail"]) {
        if ([[segue destinationViewController] isKindOfClass:[AZXAccountViewController class]]) {
            AZXAccountViewController *viewController = [segue destinationViewController];
            NSIndexPath *indexPath = [self.dayTableView indexPathForSelectedRow];
            
            // 通知AZXAccountViewController是从此页面转过去的，且告诉其日期
            viewController.passedDate = self.uniqueDateArray[indexPath.row];
        }
    }
}


@end
