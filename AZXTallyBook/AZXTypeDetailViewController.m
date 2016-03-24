//
//  AZXTypeDetailViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/14.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXTypeDetailViewController.h"
#import "AppDelegate.h"
#import "Account.h"
#import "AZXAllHistoryTableViewCell.h"
#import "AZXAccountViewController.h"
#import <CoreData/CoreData.h>

@interface AZXTypeDetailViewController () <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *moneyLabel;

@property (weak, nonatomic) IBOutlet UITableView *typeTableView;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSArray *dataArray; // fetch而来的数据

@property (strong, nonatomic) NSArray *uniqueDateArray;

@property (strong, nonatomic) NSArray *uniqueMoneyArray;

@property (assign, nonatomic) double totalMoney;

@end

@implementation AZXTypeDetailViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.typeTableView.dataSource = self;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self fetchData];
    
    [self filterData];
    
    [self setLabel];
    
    [self.typeTableView reloadData];
}

- (void)fetchData {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@ and type == %@ and incomeType == %@", self.date, self.type, self.incomeType]];
    
    NSError *error = nil;
    self.dataArray = [self.managedObjectContext executeFetchRequest:request error:&error];
}

- (void)filterData {
    NSMutableArray *tmpDateArray = [NSMutableArray array];
    NSMutableArray *tmpMoneyArray = [NSMutableArray array];
    double tmpTotalMoney = 0;
    
    for (Account *account in self.dataArray) {
        [tmpDateArray addObject:account.date];
        tmpTotalMoney += [account.money doubleValue];
    }
    
    self.totalMoney = tmpTotalMoney;
    
    NSSet *set = [NSSet setWithArray:[tmpDateArray copy]];
    
    self.uniqueDateArray = [set sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES]]];
    
    for (NSInteger i = 0; i < self.uniqueDateArray.count; i++) {
        // 将某一天的过滤出来
        NSArray *accountsInOneDay = [self.dataArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"date == %@", self.uniqueDateArray[i]]];
        
        // 计算这一天金额总量
        double tmpTotalMoney = 0;
        for (Account *account in accountsInOneDay) {
            tmpTotalMoney += [account.money doubleValue];
        }
        
        [tmpMoneyArray addObject:[NSNumber numberWithDouble:tmpTotalMoney]];
    }
    
    self.uniqueMoneyArray = [tmpMoneyArray copy];
}

- (void)setLabel {
    NSString *str;
    UIColor *color;
    // 支出用红色，收入用绿色
    if ([self.incomeType isEqualToString:@"income"]) {
        str = @"共收入:";
        color = [UIColor blueColor];
    } else {
        str = @"共支出:";
        color = [UIColor redColor];
    }
    
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  %@  %@ %@", self.date, self.type, str, [NSNumber numberWithDouble:self.totalMoney]]];
    
    NSInteger formerStringLength = self.date.length + 2 + self.type.length + 2 + str.length + 1;
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, formerStringLength)];
    
    // 金额部分用color(不同颜色)
    [mutString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(formerStringLength, [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalMoney]].length)];
    
    [self.moneyLabel setAttributedText:mutString];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueDateArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AZXAllHistoryTableViewCell *cell = [self.typeTableView dequeueReusableCellWithIdentifier:@"typeDetailCell" forIndexPath:indexPath];
    cell.date.text = self.uniqueDateArray[indexPath.row];
    
    cell.money.text = [NSString stringWithFormat:@"%@", self.uniqueMoneyArray[indexPath.row]];
    if ([self.incomeType isEqualToString:@"income"]) {
        cell.money.textColor = [UIColor blueColor];
    } else {
        cell.money.textColor = [UIColor redColor];
    }
    
    return cell;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToDayDetail"]) {
        if ([[segue destinationViewController] isKindOfClass:[AZXAccountViewController class]]) {
            AZXAccountViewController *viewController = [segue destinationViewController];
            
            NSIndexPath *indexPath = [self.typeTableView indexPathForSelectedRow];
            
            viewController.passedDate = self.uniqueDateArray[indexPath.row];
            viewController.selectedType = self.type;
        }
    }
}


@end
