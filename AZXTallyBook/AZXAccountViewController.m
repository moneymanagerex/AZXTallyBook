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

@property (nonatomic, strong) NSArray *typeArray; // 存放各个类型，以便如果是从别的界面转来可以选中该行

@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation AZXAccountViewController

// navigation控制时从下一界面返回时不会再次调用viewDidLoad，应用viewWillAppear
- (void)viewDidLoad {
    [super viewDidLoad];
    self.accountTableView.delegate = self;
    self.accountTableView.dataSource = self;
    
    // 取得managedObjectContext
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    self.defaults = [NSUserDefaults standardUserDefaults];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.passedDate) { // 若有别处传来的日期(此时是那个没有记账按钮的UI在显示)
        self.navigationItem.title = self.passedDate;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.selectedType) {
        // 如果是从统计类型界面跳转而来
        NSArray *indexArray = [self indexsOfObject:self.selectedType InArray:self.typeArray];

        // 将相应type的行背景加深
        for (NSNumber *indexNumber in indexArray) {
            AZXAccountTableViewCell *cell = [self.accountTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[indexNumber integerValue] inSection:0]];
            
            cell.backgroundColor = [UIColor lightGrayColor];
        }
    }
}

// 返回一个含有该object相同的元素所在index的数组，且元素被封装成NSNumber
- (NSArray *)indexsOfObject:(id)object InArray:(NSArray *)array {
    NSMutableArray *tmpArray = [NSMutableArray array];

    for (NSInteger i = 0; i < array.count; i++) {
        id obj = array[i];
        if ([obj isEqual:object]) {
            [tmpArray addObject:[NSNumber numberWithInteger:i]];
        }
    }
    return [tmpArray copy];
}

- (void)fetchAccounts {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.passedDate]];  // 根据传来的date筛选需要的结果
    
    NSError *error = nil;
    self.fetchedResults = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:request error:&error]];
    
    // 暂时储存类型
    NSMutableArray *tmpTypeArray = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.fetchedResults.count; i++) {
        Account *account = self.fetchedResults[i];
        [tmpTypeArray addObject:account.type];
    }
    
    // 这一步是为从统计类型界面跳转而来做准备的，为了进入界面就默认从所有类型中选中该类型
    self.typeArray = [tmpTypeArray copy];
}

- (void)calculateMoneySumAndSetText {
    // 计算结余总金额
    double moneySum = 0;
    for (Account *account in self.fetchedResults) {
        if ([account.incomeType isEqualToString:@"income"]) {
            NSLog(@"income %f", [account.money doubleValue]);
            moneySum += [account.money doubleValue];
        } else {
            NSLog(@"expense %f", [account.money doubleValue]);
            moneySum -= [account.money doubleValue];
        }
    }
    
    NSLog(@"sum %@ %f", [NSNumber numberWithDouble:moneySum], moneySum);
    
    NSString *moneySumString = [NSString stringWithFormat:@"今日结余: %@", [NSNumber numberWithDouble:moneySum]];
    
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
    
    // 此处的图片名称通过相应的type作为key从NSUserDefaults中取出
    cell.typeImage.image = [UIImage imageNamed:[self.defaults objectForKey:cell.typeName.text]];
    
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
