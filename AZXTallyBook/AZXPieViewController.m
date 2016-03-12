//
//  AZXPieViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/12.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXPieViewController.h"
#import "AZXPieView.h"
#import "AppDelegate.h"
#import "Account.h"
#import <CoreData/CoreData.h>

@interface AZXPieViewController () <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet AZXPieView *pieView;

@property (weak, nonatomic) IBOutlet UITableView *typeTableView;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *rightSwipe; // 右滑手势

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *leftSwipe; // 左滑手势

@property (strong, nonatomic) NSString *incomeType;

@property (assign, nonatomic) NSInteger totalMoney; // 收入/支出总额

@property (strong, nonatomic) NSArray *dataArray; // fetch来的Accounts

@property (strong, nonatomic) NSArray *uniqueDateArray;

@property (strong, nonatomic) NSArray *uniqueTypeArray;

@property (strong, nonatomic) NSArray *sortedMoneyArray;

@property (strong, nonatomic) NSDictionary *dict; // 储存有[type:money]的字典

@property (assign, nonatomic) NSInteger currentIndex; // 当前要显示的数据的index(随swipe而增减)

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation AZXPieViewController

- (NSInteger)currentIndex {
    if (!_currentIndex) {
        _currentIndex = 0; // 默认为0
    }
    return _currentIndex;
}

- (NSString *)incomeType {
    if (!_incomeType) {
        _incomeType = @"expense"; // 默认为支出
    }
    return _incomeType;
}

- (IBAction)segValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
        [self fetchData];
    } else {
        self.incomeType = @"income";
        [self fetchData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.typeTableView.dataSource = self;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    [self setSwipeGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self fetchData];

    [self filterData];
}

- (void)setSwipeGesture {
    // 分别设置左右滑动手势
    self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        
    } else if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        
    }
}

- (void)fetchData {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    if (self.uniqueDateArray[self.currentIndex] == nil) {
        // 若果还未设置，默认显示当前所处月份
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        NSString *date = [[dateFormatter stringFromDate:[NSDate date]] substringToIndex:7];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@ and incomeType == %@", date, self.incomeType]];
    } else {
        NSString *date = self.uniqueDateArray[self.currentIndex];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] and incomeType == %@", date, self.incomeType]];
    }
    
    NSError *error = nil;
    self.dataArray = [self.managedObjectContext executeFetchRequest:request error:&error];
}


// 得到了totalMoney(总金额)，sortedMoneyArray(某一类别的金额的数组)，uniqueTypeArray(类别数组，与左边的数组排序相同)，uniqueDateArray(日期数组)
- (void)filterData {
    NSMutableArray *tmpTypeArray = [NSMutableArray array];
    NSMutableArray *tmpAccountArray = [NSMutableArray array];
    NSDictionary *tmpDict = [NSMutableDictionary dictionary];
    NSMutableArray *tmpMoneyArray = [NSMutableArray array];
    NSMutableArray *tmpDateArray = [NSMutableArray array];
    
    NSInteger tmpMoney = 0;
    for (Account *account in self.dataArray) {
        [tmpTypeArray addObject:account.type];
        [tmpAccountArray addObject:account];
        tmpMoney += [account.money integerValue];
        [tmpDateArray addObject:[account.date substringToIndex:7]];
    }
    
    self.totalMoney = tmpMoney;
    
    // 去掉重复元素
    NSSet *typeSet = [NSSet setWithArray:[tmpTypeArray copy]];
    
    // 得到降序的无重复元素的日期数组
    NSSet *dateSet = [NSSet setWithArray:[tmpDateArray copy]];
    self.uniqueDateArray = [dateSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]];
    
    for (NSString *type in typeSet) {
        // 从中过滤其中一个类别的所有Account，然后得到一个类别的总金额
        NSArray *array = [tmpAccountArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", type]];
        NSInteger totalMoneyInOneType = 0;
        for (Account *account in array) {
            totalMoneyInOneType += [account.money integerValue];
        }
        
        // 将金额封装成NSNumber来排序
        [tmpMoneyArray addObject:[NSNumber numberWithInteger:totalMoneyInOneType]];
        
        // 将type加入数组
        [tmpTypeArray addObject:type];
        
        // 这里使用字典是为了使type和money能关联起来，而且因为money要排序的原因无法使它们在各自数组保持相同的index，所以用字典的方法
        tmpDict = [NSDictionary dictionaryWithObjects:[tmpMoneyArray copy] forKeys:[tmpTypeArray copy]];
        
    }
    
    // 降序排列
    self.sortedMoneyArray = [tmpMoneyArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]];
    
    NSMutableArray *tmpTypes = [NSMutableArray array];
    NSInteger x = 0;
    for (NSInteger i = 0; i < self.sortedMoneyArray.count; i++) {
        // 因为可能一个金额对应着多个类型，判断是否出现此情况，若出现，则将x++, 取出数组其余类型
        if (i > 0 && (self.sortedMoneyArray[i-1] == self.sortedMoneyArray[i])) {
            x++;
        } else {
            x = 0;
        }
        NSString *type = [tmpDict allKeysForObject:self.sortedMoneyArray[i]][x];
        // 此数组中加入的顺序与moneyArray中一样
        [tmpTypes addObject:type];
    }
    
    self.uniqueTypeArray = [tmpTypes copy];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
