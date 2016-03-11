//
//  AZXAllHistoryViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/11.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXAllHistoryViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Account.h"
#import "AZXAllHistoryTableViewCell.h"
#import "AZXMonthHIstoryViewController.h"

@interface AZXAllHistoryViewController () <UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *totalDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *remainMoneyLabel;

@property (weak, nonatomic) IBOutlet UITableView *monthTableView;

@property (strong, nonatomic) NSArray *dataArray; // 储存fetch来的所有Account

@property (strong, nonatomic) NSMutableArray *monthIncome; // 每个月的收入金额

@property (strong, nonatomic) NSMutableArray *monthExpense; // 每个月的支出金额

@property (assign, nonatomic) NSInteger totalIncome; // 总收入

@property (assign, nonatomic) NSInteger totalExpense; // 总支出

@property (strong, nonatomic) NSArray *uniqueDateArray; // 储存不重复月份的数组

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end

@implementation AZXAllHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.monthTableView.dataSource = self;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    // 数组的初始化
    self.monthIncome = [NSMutableArray array];
    self.monthExpense = [NSMutableArray array];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self fetchData];
    
    [self filterUniqueDate];
    
    [self calculateMonthsMoney];
    
    [self setTotalLabel];
    
    [self.monthTableView reloadData];
}

- (void)fetchData {
    // 得到所有account
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    NSError *error = nil;
    self.dataArray = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
}

- (void)filterUniqueDate {
    NSMutableArray *dateArray = [NSMutableArray array];
    
    // 将月份组成一个数组
    for (Account *account in self.dataArray) {
        // 取前7位的年和月份
        [dateArray addObject:[account.date substringToIndex:7]];
    }
    
    // 用NSSet得到不重复的月份
    NSSet *set = [NSSet setWithArray:[dateArray copy]];
    
    // 再得到排序后的数组
    NSArray *sortDesc = @[[[NSSortDescriptor alloc] initWithKey:nil ascending:YES]];
    self.uniqueDateArray = [set sortedArrayUsingDescriptors:sortDesc];
    
}

- (void)calculateMonthsMoney {
    // 先将数据取得添加到暂时数组中，防止每次调用这方法在没有数据改变的情况下金额显示增大
    NSInteger tmpTotalIncome = 0;
    NSInteger tmpTotalExpense = 0;
    NSMutableArray *tmpMonthIncome = [NSMutableArray array];
    NSMutableArray *tmpMonthExpense = [NSMutableArray array];
    
    
    for (NSInteger i = 0; i < self.uniqueDateArray.count; i++) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        
        // 过滤月份
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@", self.uniqueDateArray[i]]];
        
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
        
        // 加到暂存总收入支出中
        tmpTotalIncome += income;
        tmpTotalExpense += expense;
        
        // 并将结果暂时储存在收入/支出数组相应月份在uniqueDateArray的位置
        // 方便到时候设置cell的各个属性
        [tmpMonthIncome addObject:[NSString stringWithFormat:@"%ld", (long)income]];
        [tmpMonthExpense addObject:[NSString stringWithFormat:@"%ld", (long)expense]];
        
    }
    
    
    // 将暂存值赋给属性以显示在UI上
    self.totalIncome = tmpTotalIncome;
    self.totalExpense = tmpTotalExpense;
    
    self.monthIncome = tmpMonthIncome;
    self.monthExpense = tmpMonthExpense;

}

- (void)setTotalLabel {
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"总收入: %ld  总支出: %ld", (long)self.totalIncome, (long)self.totalExpense]];
    
    // 示意图: 总收入: xxx(不限长度)  总支出: xxx(不限长度)
    NSString *incomeString = [NSString stringWithFormat:@"%ld", (long)self.totalIncome];
    NSString *expenseString = [NSString stringWithFormat:@"%ld", (long)self.totalExpense];

    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 4)];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(5, incomeString.length)];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(5 + incomeString.length + 2, 4)];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(5 + incomeString.length + 2 + 5, expenseString.length)];
    
    [self.totalDetailLabel setAttributedText:mutString];
    
    
    // 计算结余
    NSInteger remainMoney = self.totalIncome - self.totalExpense;
    
    self.remainMoneyLabel.text = [NSString stringWithFormat:@"结余: %ld", (long)remainMoney];
    
}

#pragma UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueDateArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AZXAllHistoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"monthAccountCell" forIndexPath:indexPath];
    
    cell.date.text = self.uniqueDateArray[indexPath.row];
    
    NSMutableAttributedString * mutString = [self configMoneyLabelWithIndexPath:indexPath];
    
    [cell.money setAttributedText:mutString];

    return cell;
}

- (NSMutableAttributedString *)configMoneyLabelWithIndexPath:(NSIndexPath *)indexPath {
    // 收入金额
    NSString  *income = self.monthIncome[indexPath.row];
    
    NSString *incomeString = [@"收入: " stringByAppendingString:income];
    
    // 为了排版，固定金额数目为7位，不足补空格
    for (NSInteger i = income.length; i < 7; i++) {
        incomeString = [incomeString stringByAppendingString:@" "];
    }
    
    // 支出金额(前留一空格)
    NSString *expense = self.monthExpense[indexPath.row];
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
    if ([segue.identifier isEqualToString:@"showMonthDetail"]) {
        if ([[segue destinationViewController] isKindOfClass:[AZXMonthHIstoryViewController class]]) {
            AZXMonthHIstoryViewController *viewController = [segue destinationViewController];
            NSIndexPath *indexPath = [self.monthTableView indexPathForSelectedRow];
            
            // 将被点击cell的相应属性传过去
            viewController.date = self.uniqueDateArray[indexPath.row];
        }
    }
}


@end
