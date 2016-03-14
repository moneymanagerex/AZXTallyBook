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
#import "AZXPieTableViewCell.h"
#import "AZXTypeDetailViewController.h"
#import <CoreData/CoreData.h>

@interface AZXPieViewController () <UITableViewDataSource, AZXPieViewDataSource>

@property (weak, nonatomic) IBOutlet AZXPieView *pieView;

@property (weak, nonatomic) IBOutlet UITableView *typeTableView;

@property (weak, nonatomic) IBOutlet UILabel *moneyLabel;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *rightSwipe; // 右滑手势

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *leftSwipe; // 左滑手势

@property (strong, nonatomic) UILabel *nullLabel; // 用来显示"暂无数据"

@property (strong, nonatomic) NSString *incomeType;

@property (assign, nonatomic) double totalMoney; // 收入/支出总额

@property (strong, nonatomic) NSArray *dataArray; // fetch来的Accounts

@property (strong, nonatomic) NSArray *uniqueDateArray;

@property (strong, nonatomic) NSArray *uniqueTypeArray;

@property (strong, nonatomic) NSArray *sortedMoneyArray;

@property (strong, nonatomic) NSArray *sortedPercentArray; // 相应类别所占总金额的比例

@property (strong, nonatomic) NSDictionary *dict; // 储存有[type:money]的字典

@property (assign, nonatomic) NSInteger currentIndex; // 当前要显示的数据的index(随swipe而增减)

@property (strong, nonatomic) NSString *currentDateString; // 当前日期，用来显示与筛选fetch结果

@property (strong, nonatomic) NSDate *currentDate; // 用来swipe时加减日期

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSArray *colors; // 一条渐变的颜色带

@property (strong, nonatomic) NSArray *colorArray; // 储存各种颜色(对应不同的type)

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

- (NSArray *)colors {
    if (!_colors) {
        _colors = @[[UIColor colorWithRed:252/255.0 green:25/255.0 blue:28/255.0 alpha:1],
                        [UIColor colorWithRed:253/255.0 green:105/255.0 blue:33/255.0 alpha:1],
                        [UIColor colorWithRed:254/255.0 green:200/255.0 blue:46/255.0 alpha:1],
                        [UIColor colorWithRed:255/255.0 green:245/255.0 blue:54/255.0 alpha:1],
                        [UIColor colorWithRed:217/255.0 green:253/255.0 blue:53/255.0 alpha:1],
                        [UIColor colorWithRed:140/255.0 green:253/255.0 blue:49/255.0 alpha:1],
                        [UIColor colorWithRed:42/255.0 green:253/255.0 blue:130/255.0 alpha:1],
                        [UIColor colorWithRed:44/255.0 green:253/255.0 blue:218/255.0 alpha:1],
                        [UIColor colorWithRed:43/255.0 green:244/255.0 blue:253/255.0 alpha:1],
                        [UIColor colorWithRed:29/255.0 green:166/255.0 blue:250/255.0 alpha:1],
                        [UIColor colorWithRed:18/255.0 green:92/255.0 blue:249/255.0 alpha:1],
                        [UIColor colorWithRed:142/255.0 green:37/255.0 blue:248/255.0 alpha:1],
                        [UIColor colorWithRed:219/255.0 green:39/255.0 blue:249/255.0 alpha:1],
                        [UIColor colorWithRed:249/255.0 green:31/255.0 blue:181/255.0 alpha:1]];
    }  // 共14种颜色，从红到紫，呈彩虹状渐变
    return _colors;
}

- (IBAction)segValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
        [self refreshAll];
    } else {
        self.incomeType = @"income";
        [self refreshAll];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.typeTableView.dataSource = self;
    self.pieView.dataSource = self;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    [self setSwipeGesture];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshAll];
}

- (void)viewWillDisappear:(BOOL)animated {
    // 离开界面时将图上label全部移除
    [self.pieView removeAllLabel];
}



- (void)refreshAll {
    [self.pieView removeAllLabel];
    
    [self.nullLabel removeFromSuperview];
    
    [self fetchData];
    
    [self filterData];
    
    [self setMoneyLabel];
    
    [self.typeTableView reloadData];
    
    [self.pieView reloadData];
}

- (void)setSwipeGesture {
    // 分别设置左右滑动手势
    self.leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    self.rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    [self.view addGestureRecognizer:self.leftSwipe];
    [self.view addGestureRecognizer:self.rightSwipe];
    
    self.leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    self.rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    // 创建一个标准日历
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        // 左滑月份加1
        [comps setMonth:1];
        self.currentDate = [calendar dateByAddingComponents:comps toDate:self.currentDate options:0];
    } else if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        // 右滑月份减1
        [comps setMonth:-1];
        self.currentDate = [calendar dateByAddingComponents:comps toDate:self.currentDate options:0];
    }
    
    [self refreshAll];
}

- (void)fetchData {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    // 设置日期格式
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    if (self.currentDateString == nil) {
        // 如果还未设置，默认显示当前所处月份
        self.currentDate = [NSDate date];
        self.currentDateString = [[dateFormatter stringFromDate:self.currentDate] substringToIndex:7];
        
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@ and incomeType == %@", self.currentDateString, self.incomeType]];
    } else {
        self.currentDateString = [[dateFormatter stringFromDate:self.currentDate] substringToIndex:7];
        [request setPredicate:[NSPredicate predicateWithFormat:@"date beginswith[c] %@ and incomeType == %@", self.currentDateString, self.incomeType]];
    }
    
    NSError *error = nil;
    self.dataArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (self.dataArray.count == 0) {
        NSLog(@"null!!!!!!!!!!!!!!!");
        // 如果没有数据，中间显示"暂无数据"
        self.nullLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        self.nullLabel.text = @"暂无数据";
        self.nullLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        self.nullLabel.textColor = [UIColor lightGrayColor];
        [self.nullLabel sizeToFit];
        self.nullLabel.center = self.view.center;
        [self.view addSubview:self.nullLabel];
    }
}


// 得到了totalMoney(总金额)，sortedMoneyArray(某一类别的金额的数组)，uniqueTypeArray(类别数组，与左边的数组排序相同)，uniqueDateArray(日期数组)，sortedPercentArray(每个类别所花金额占总金额的比例)，colorArray（储存各种颜色对应不同的type)
- (void)filterData {
    // 设置各个属性的暂存数组，防止直接数据加入属性多次调用方法导致数据叠加
    NSMutableArray *tmpTypeArray = [NSMutableArray array];
    NSMutableArray *tmpAccountArray = [NSMutableArray array];
    NSDictionary *tmpDict = [NSMutableDictionary dictionary];
    NSMutableArray *tmpMoneyArray = [NSMutableArray array];
    NSMutableArray *tmpDateArray = [NSMutableArray array];
    NSMutableArray *tmpSortedPercentArray = [NSMutableArray array];
    NSMutableArray *tmpColorArray = [NSMutableArray array];
    
    double tmpMoney = 0;
    for (Account *account in self.dataArray) {
        [tmpTypeArray addObject:account.type];
        [tmpAccountArray addObject:account];
        tmpMoney += [account.money doubleValue];
        [tmpDateArray addObject:[account.date substringToIndex:7]];
    }
    
    self.totalMoney = tmpMoney;
    
    // 去掉重复元素
    NSSet *typeSet = [NSSet setWithArray:[tmpTypeArray copy]];
    
    //
    tmpTypeArray = [NSMutableArray array];
    
    // 得到降序的无重复元素的日期数组
    NSSet *dateSet = [NSSet setWithArray:[tmpDateArray copy]];
    self.uniqueDateArray = [dateSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]];
    
    for (NSString *type in typeSet) {
        NSLog(@"type %@", type);
        // 从中过滤其中一个类别的所有Account，然后得到一个类别的总金额
        NSArray *array = [tmpAccountArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", type]];
        
        double totalMoneyInOneType = 0;
        for (Account *account in array) {
            totalMoneyInOneType += [account.money doubleValue];
        }
        
        // 将金额封装成NSNumber来排序
        [tmpMoneyArray addObject:[NSNumber numberWithDouble:totalMoneyInOneType]];
        
        // 将type加入数组
        [tmpTypeArray addObject:type];
        
    }
    
    // 这里使用字典是为了使type和money能关联起来，而且因为money要排序的原因无法使它们在各自数组保持相同的index，所以用字典的方法
    tmpDict = [NSDictionary dictionaryWithObjects:[tmpMoneyArray copy] forKeys:[tmpTypeArray copy]];
    
    // 降序排列
    self.sortedMoneyArray = [tmpMoneyArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nil ascending:NO]]];
    
    NSMutableArray *tmpTypes = [NSMutableArray array];
    NSInteger x = 0;
    
    double tmpTotalPercent = 0;
    
    for (NSInteger i = 0; i < self.sortedMoneyArray.count; i++) {
        // 将相应百分比(小数点后两位)加入数组
        // 此处为了总和为100%，将最后一个设为总额减去数组前除最后一个外所有的元素的百分比
        double money = [self.sortedMoneyArray[i] doubleValue];
        
        double percent = [[NSString stringWithFormat:@"%.2f",money/self.totalMoney*100] doubleValue];
        
        if (i != self.sortedMoneyArray.count - 1) {
            // 如果不是数组最后一个的话，直接加入数组
            [tmpSortedPercentArray addObject:[NSNumber numberWithDouble:percent]];
            // 并累计前面百分比的总和
            tmpTotalPercent += percent;
        } else {
            // 如果是最后一个元素，通过用1减去前面的总和得到
            [tmpSortedPercentArray addObject:[NSNumber numberWithDouble:[[NSString stringWithFormat:@"%.2f", 100-tmpTotalPercent] doubleValue]]];
        }

        // 将相应颜色加入数组(超过数组的14时从头开始)
        [tmpColorArray addObject:self.colors[i%14]];
        
        // 将相应类型加入数组
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
    
    self.sortedPercentArray = [tmpSortedPercentArray copy];
    self.colorArray = [tmpColorArray copy];
    self.uniqueTypeArray = [tmpTypes copy];
}

- (void)setMoneyLabel {
    NSMutableAttributedString *mutString;
    if ([self.incomeType isEqualToString:@"income"]) {
        mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ 总收入: %@", self.currentDateString, [NSNumber numberWithDouble:self.totalMoney]]];
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(13, [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalMoney]].length)];
    } else {
        mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ 总支出: %@", self.currentDateString, [NSNumber numberWithDouble:self.totalMoney]]];
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(13, [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:self.totalMoney]].length)];

    }
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, 12)];
    
    [self.moneyLabel setAttributedText:mutString];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueTypeArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AZXPieTableViewCell *cell = [self.typeTableView dequeueReusableCellWithIdentifier:@"pieTypeCell" forIndexPath:indexPath];
    
    cell.colorView.backgroundColor = self.colorArray[indexPath.row];
    
    NSString *type = self.uniqueTypeArray[indexPath.row];
    NSNumber *money = self.sortedMoneyArray[indexPath.row];
    
    NSNumber *percent = self.sortedPercentArray[indexPath.row];
    NSString *percentString = [NSString stringWithFormat:@"%@", percent];
    
    NSMutableAttributedString *mutString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@     %@     %@%%", type, money, [self filterLastZeros:percentString]]];
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, type.length)];
    
    // 计算金额显示的长度
    NSInteger moneyLength = [NSString stringWithFormat:@"%@", money].length;
    
    if ([self.incomeType isEqualToString:@"income"]) {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(type.length + 5, moneyLength)];
    } else {
        [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(type.length + 5, moneyLength)];
    }
    
    [mutString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(type.length + 5 + moneyLength + 5, percentString.length + 1)];
    
    [cell.moneyLabel setAttributedText:mutString];
    
    return cell;
}

- (NSString *)filterLastZeros:(NSString *)string {
    NSString *str = string;
    if ([str containsString:@"."] && [string substringFromIndex:[string rangeOfString:@"."].location].length > 3) {
        // 如果小数点后大于2位，只保留两位
        str = [string substringToIndex:[string rangeOfString:@"."].location+3];
    }
    if ([str containsString:@"."]) {
        if ([[str substringFromIndex:str.length-1] isEqualToString: @"0"]) {
            // 如果最后一位为0，舍弃
            return [str substringToIndex:str.length-1];
        } else if ([[str substringFromIndex:str.length-2] isEqualToString:@"00"]) {
            // 如果后两位为0，舍弃
            return [str substringToIndex:str.length-2];
        } else {
            return str;
        }
    }
    return str;
}


#pragma mark - AZXPieView DataSource

- (NSArray *)percentsForPieView:(AZXPieView *)pieView {
    return self.sortedPercentArray;
}

- (NSArray *)colorsForPieView:(AZXPieView *)pieView {
    return self.colorArray;
}

- (NSArray *)typesForPieView:(AZXPieView *)pieView {
    return self.uniqueTypeArray;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTypeDetail"]) {
        if ([[segue destinationViewController] isKindOfClass:[AZXTypeDetailViewController class]]) {
            AZXTypeDetailViewController *viewController = [segue destinationViewController];
            viewController.date = self.currentDateString;
            
            viewController.incomeType = self.incomeType;
            
            NSIndexPath *indexPath = [self.typeTableView indexPathForSelectedRow];
            
            viewController.type = self.uniqueTypeArray[indexPath.row];
            
        }
    }
}


@end
