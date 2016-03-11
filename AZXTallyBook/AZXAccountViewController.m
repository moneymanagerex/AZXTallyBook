//
//  AZXAccountViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXAccountViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "AZXAccountTableViewCell.h"
#import "AZXNewAccountTableViewController.h"
#import "Account.h"

@interface AZXAccountViewController () <UITableViewDelegate, UITableViewDataSource, PassingDateDelegate>

@property (weak, nonatomic) IBOutlet UITableView *accountTableView;

@property (weak, nonatomic) IBOutlet UILabel *moneySumLabel; // 结余总金额

@property (weak, nonatomic) IBOutlet UIButton *addNewButton;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSMutableArray *fetchedResults;

@end

@implementation AZXAccountViewController
- (BOOL)isSegueFromHistory {
    if (!_isSegueFromHistory) {
        _isSegueFromHistory = NO; // 默认为NO
    }
    return _isSegueFromHistory;
}

// navigation控制时从下一界面返回时不会再次调用viewDidLoad，应用viewWillAppear
- (void)viewDidLoad {
    [super viewDidLoad];
    self.accountTableView.delegate = self;
    self.accountTableView.dataSource = self;
    
    // 取得managedObjectContext
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    if (self.isSegueFromHistory) {
        //self.accountTableView.frame.size.height += self.addNewButton.frame.size.height;
        [self.addNewButton removeFromSuperview];

    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.passedDate) { // 将控制器的标题设为该新账本所在的日期
        self.title = self.passedDate;
    } else {
        // 刚打开应用时，将passedDate设为当前日期(为了在fetchAccount时能筛选并展示当天的账单)
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        self.passedDate = [dateFormatter stringFromDate:[NSDate date]];
    }
    
    [self fetchAccounts];
    [self.accountTableView reloadData];
    
    // 计算结余总额
    [self calculateMoneySumAndSetText];
    
}

- (void)fetchAccounts {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.passedDate]];  // 根据传来的date筛选需要的结果
    
    NSError *error = nil;
    self.fetchedResults = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
}

- (void)calculateMoneySumAndSetText {
    // 计算结余总金额
    NSInteger moneySum = 0;
    for (Account *account in self.fetchedResults) {
        if ([account.incomeType isEqualToString:@"income"]) {
            moneySum += [account.money integerValue];
        } else {
            moneySum -= [account.money integerValue];
        }
    }
    
    NSString *moneySumString = [NSString stringWithFormat:@"今日结余: %ld", (long)moneySum];
    
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:moneySumString];
    
    // 在moneySumLabel上前面字体黑色，后半段根据正负决定颜色
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 5)];
    
    if (moneySum >= 0) {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(5, moneySumString.length - 5)];
    } else {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(5, moneySumString.length - 5)];
    }
    
    [self.moneySumLabel setAttributedText:mutString];
}

#pragma mark - UITableViewDataSource

- (void)configureCell:(AZXAccountTableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath {
    Account *account = [self.fetchedResults objectAtIndex:indexPath.row];
    cell.typeName.text = account.type;
    cell.money.text = account.money;
    cell.typeImage.image = [UIImage imageNamed:cell.typeName.text];
    
    // 根据类型选择不同颜色
    if ([account.incomeType isEqualToString:@"income"]) {
        cell.money.textColor = [UIColor blueColor];
    } else {
        cell.money.textColor = [UIColor redColor];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AZXAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetchedResults.count;
}


#pragma mark - UITabelView Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // 首先删除CoreData里的数据
        [self.managedObjectContext deleteObject:self.fetchedResults[indexPath.row]];
        // 然后移除提供数据源的fetchResults(不然会出现tableView的update问题而crush)
        [self.fetchedResults removeObjectAtIndex:indexPath.row];
        // 删除tableView的行
        [self.accountTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        // 最后更新UI
        [self calculateMoneySumAndSetText];
    }
}


#pragma mark - PassingDateDelegate

- (void)viewController:(AZXNewAccountTableViewController *)controller didPassDate:(NSString *)date {
    self.passedDate = date;  // 接收从AZXNewAccountTableViewController传来的date值，用做Predicate来筛选Fetch的ManagedObject
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue destinationViewController] isKindOfClass:[AZXNewAccountTableViewController class]]) {  // segue时将self设为AZXNewAccountTableViewController的代理
        AZXNewAccountTableViewController *viewController = [segue destinationViewController];
        viewController.delegate = self;
    }
    
    if ([segue.identifier isEqualToString:@"addNewAccount"]) {
        // 点击记账按钮时，创建一个新账本，并告知不是点击tableView转来
        AZXNewAccountTableViewController *viewController = [segue destinationViewController];
        viewController.isSegueFromTableView = NO;
    } else if ([segue.identifier isEqualToString:@"segueToDetailView"]) {
        // 点击已保存的账本记录，查看详细，并告知是点击tableView而来
        // 转到详细页面时，要显示被点击cell的内容，所以要将account传过去，让其显示相应内容
        AZXNewAccountTableViewController *viewController = [segue destinationViewController];
        viewController.isSegueFromTableView = YES;
        viewController.accountInSelectedRow = self.fetchedResults[self.accountTableView.indexPathForSelectedRow.row];
    }
}


@end
