//
//  AZXNewAccountTableViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXNewAccountTableViewController.h"
#import "AppDelegate.h"
#import "AZXAccountViewController.h"

@interface AZXNewAccountTableViewController () <UITextViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *moneyTextField;

@property (weak, nonatomic) IBOutlet UILabel *typeLabel;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UITextView *detailTextView; //详细描述

@property (strong, nonatomic) UIDatePicker *datePicker; //日期选择器

@property (strong, nonatomic) UIPickerView *pickerView; // 类型选择器

@property (strong, nonatomic) NSString *incomeType; //收入(income)还是支出(expense)

@property (strong, nonatomic) UIBarButtonItem *doneButton;

@property (strong, nonatomic) UIView *shadowView; // 插入的灰色夹层

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@property (strong, nonatomic) NSMutableArray *incomeArray; // 分别用来储存两种类型的种类

@property (strong, nonatomic) NSMutableArray *expenseArray;

@end

@implementation AZXNewAccountTableViewController

#pragma mark - view did load

- (BOOL)isSegueFromTableView {
    if (!_isSegueFromTableView) {
        _isSegueFromTableView = NO; // 默认为NO
    }
    return _isSegueFromTableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 自定义"返回"按钮(左侧)
    [self customizeLeftButton];
    
    // 自定义"取消"按钮(右侧)
    [self customizeRightButton];
    
    // 判断是怎样转到这个界面的
    if (self.isSegueFromTableView) {
        // 如果是点击tableView而来，显示传递过来的各个属性
        self.moneyTextField.text = self.accountInSelectedRow.money;
        self.dateLabel.text = self.accountInSelectedRow.date;
        self.detailTextView.text = self.accountInSelectedRow.detail;
        self.incomeType = self.accountInSelectedRow.incomeType;
        self.typeLabel.text = self.accountInSelectedRow.type;
        
        if ([self.incomeType isEqualToString:@"income"]) {
            self.moneyTextField.textColor = [UIColor blueColor];
        } else {
            self.moneyTextField.textColor = [UIColor redColor];
        }

        
    } else {
        // 如果是点击记账按钮而来
        //日期显示默认为当前日期
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        self.dateLabel.text = [dateFormatter stringFromDate:[NSDate date]];
        
        //利用textView的delegate实现其placeholder
        self.detailTextView.delegate = self;
        self.detailTextView.text = @"详细描述(选填)";
        self.detailTextView.textColor = [UIColor lightGrayColor];
        
        
        //一进入界面即弹出键盘输入金额
        [self.moneyTextField becomeFirstResponder];
        self.moneyTextField.keyboardType = UIKeyboardTypeDecimalPad;
        self.moneyTextField.delegate = self;

    }
    
    // 判断是否第一次进入界面
    [self judgeFirstLoadThisView];
}

- (void)judgeFirstLoadThisView {
    // 创建userDefault单例对象
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![self.userDefaults boolForKey:@"haveLoadedAZXNewAccountTableViewController"]) {
        // 第一次进入此页面
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"教程" message:@"输入金额、类别、以及日期，点左上角的保存按钮保存，右上角按钮取消" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.userDefaults setBool:YES forKey:@"haveLoadedAZXNewAccountTableViewController"];
        }];
        
        [alert addAction:actionOK];
        
        
        [self.moneyTextField resignFirstResponder];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 视图消失时，判断是否有代理且实现了代理方法
    // 若实现了，将date传过去
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewController:didPassDate:)]) {
        [self.delegate viewController:self didPassDate:self.dateLabel.text];
    }
    
}

#pragma mark - customize left and right button

- (void)customizeLeftButton {
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(backBarButtonPressed:)];
    
    self.navigationItem.leftBarButtonItem = leftItem;
}

- (void)backBarButtonPressed:(UIButton *)sender {
    if ([self.typeLabel.text isEqualToString:@"点击输入"] || [self.moneyTextField.text isEqualToString:@""]) {
        // type和money都是必填的，如果有一个没填，则弹出AlertController提示
        [self presentAlertControllerWithMessage:@"金钱数额和类型都是必填的"];
    } else if ([self.moneyTextField.text componentsSeparatedByString:@"."].count > 2) {
        // 输入超过两个小数点
        [self presentAlertControllerWithMessage:@"输入金额不格式不符"];
    } else if ([self moneyTextContainsCharacterOtherThanNumber]) {
        // 输入纯数字以外的字符
        [self presentAlertControllerWithMessage:@"输入金额只能是数字"];
    } else {
        if (self.isSegueFromTableView) {
            // 若是从tableView传来的，则只需更新account就好
            self.accountInSelectedRow.type = self.typeLabel.text;
            self.accountInSelectedRow.detail = self.detailTextView.text;
            [self setMoneyToAccount:self.accountInSelectedRow];
            self.accountInSelectedRow.incomeType = self.incomeType;
            self.accountInSelectedRow.date = self.dateLabel.text;
        } else {
            // 若是必填项都已填好且要记新帐，则将属性保存在CoreData中
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            
            
            NSLog(@"insert");
            Account *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:appDelegate.managedObjectContext];
            
            account.type = self.typeLabel.text;
            // 截取money的小数点
            [self setMoneyToAccount:account];
            account.incomeType = self.incomeType;
            account.date = self.dateLabel.text;
            
            // 此处因为textView无法使用placeholder而将其文本默认为"详细描述(选填)"
            // 故通过判断其是否被修改来决定储存的内容
            if (![self.detailTextView.text isEqualToString:@"详细描述(选填)"]) {
                account.detail = self.detailTextView.text;
            } else {
                // 当用户未编辑详细描述时，将account的detail设为空
                account.detail = @"";
            }
        }
        
        // 跳转到前一界面
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)setMoneyToAccount:(Account *)account {
    NSString *moneyInput = self.moneyTextField.text;
    if ([moneyInput containsString:@"."]) {
        NSString *dotString = [moneyInput substringFromIndex:[moneyInput rangeOfString:@"."].location]; // 截取小数点后(包括小数点)的string
        
        if (dotString.length == 1) {
            // 若只有一个小数点，去掉最后一个小数点
            account.money = [moneyInput substringToIndex:moneyInput.length - 1];
        } else if (dotString.length == moneyInput.length) {
            // 若小数点在首位
            account.money = [@"0" stringByAppendingString:dotString];
        } else {
            // 若小数点后大于一位，则保留一位(精确到角)
            account.money = [moneyInput substringToIndex:[moneyInput rangeOfString:@"."].location + 2];
        }
    } else {
        // 若为整数
        account.money = self.moneyTextField.text;
    }

}

- (void)presentAlertControllerWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    
    [alertController addAction:action];
    
    // 弹出alertController之前先将所有的键盘收回，否则会导致之后键盘不响应
    [self.moneyTextField resignFirstResponder];
    [self.detailTextView resignFirstResponder];
    
    [self presentViewController:alertController animated:YES completion:nil];

}

- (BOOL)moneyTextContainsCharacterOtherThanNumber {
    if (![self isPureInt:self.moneyTextField.text] || ![self isPureFloat:self.moneyTextField.text]) {
        // 如果出现了纯数字以外的字符，返回YES
        return YES;
    } else {
        return NO;
    }
}

//判断是否为整形

- (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}

//判断是否为浮点形

- (BOOL)isPureFloat:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    float val;
    return[scan scanFloat:&val] && [scan isAtEnd];
}

// 自定义右侧取消按钮
- (void)customizeRightButton {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelBarButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)cancelBarButtonPressed:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提醒" message:@"确定取消？这笔账单将不会被保存" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 直接返回主界面并且不保存account
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"不，留在页面" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else {
        return 1;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2) {
        // 初始化一个datePicker并使其居中
        if (self.datePicker == nil) {
            self.datePicker = [[UIDatePicker alloc] init];
            self.datePicker.datePickerMode = UIDatePickerModeDate;
            self.datePicker.center = self.view.center;
            self.datePicker.backgroundColor = [UIColor whiteColor];
            //设为圆角矩形
            self.datePicker.layer.cornerRadius = 10;
            self.datePicker.layer.masksToBounds = YES;
            [self.view addSubview:self.datePicker];
        } else {
            [self.view addSubview:self.datePicker];
        }
        
        // 插入夹层以及加入按钮
        [self insertShadowViewAndButton];
        
        //添加监听事件
        [self.datePicker addTarget:self action:@selector(datePickerValueDidChanged:) forControlEvents:UIControlEventValueChanged];
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        // 第一次进入应用时，设置pickerView的默认数据
        [self setDefaultDataForPickerView];

        // 初始化一个pickerView并使其居中
        if (self.pickerView == nil) {
            self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 300, 180)];
            self.pickerView.center = self.view.center;
            self.pickerView.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:self.pickerView];
        } else {
            [self.view addSubview:self.pickerView];
        }
        
        // 设置delegate
        self.pickerView.delegate = self;
        self.pickerView.dataSource = self;
        
        // 插入夹层以及加入按钮
        [self insertShadowViewAndButton];
        
    }
}

#pragma mark - insert shadow view and add button

- (void)insertShadowViewAndButton {
    //插入一个浅灰色的夹层
    [self insertGrayView];
    
    //点击picker外的灰色夹层也视为确认
    [self.shadowView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerSelected)]];
    
    //导航栏右边添加“完成”按钮
    if (self.doneButton == nil) {
        self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(pickerSelected)];
    }
    self.navigationItem.rightBarButtonItem = self.doneButton;
    // 并将左边的保存按钮暂时隐藏起来
    [self.navigationItem.leftBarButtonItem setTitle:@""];
}

#pragma mark - set data for pickerView

- (void)setDefaultDataForPickerView {
    // 从userDefault中获取数据
    self.incomeArray = [self.userDefaults objectForKey:@"incomeAZX"];
    self.expenseArray = [self.userDefaults objectForKey:@"expenseAZX"];
    
    if (self.incomeArray.count == 0 || self.expenseArray.count == 0) {
        //若第一次进入应用，则为其设置默认的收入支出种类
        self.incomeArray = [NSMutableArray arrayWithArray:@[@"工资薪酬", @"奖金福利", @"生意经营", @"投资理财", @"彩票中奖", @"银行利息", @"其他收入"]];
        self.expenseArray = [NSMutableArray arrayWithArray:@[@"餐饮食品", @"交通路费", @"日常用品", @"服装首饰", @"学习教育", @"烟酒消费", @"房租水电", @"网上购物", @"运动健身", @"电子产品", @"化妆护理", @"医疗体检", @"游戏娱乐", @"外出旅游", @"油费维护", @"慈善捐赠", @"其他支出"]];
        
        // 保存至userDefaults中
        [self.userDefaults setObject:self.incomeArray forKey:@"incomeAZX"];
        [self.userDefaults setObject:self.expenseArray forKey:@"expenseAZX"];
        
        // 将type名当做key，将图片的名称当做object(这里暂时这两者是一样的，如果用户修改了类别的名称，则将新的type名当做key与图片的名称相关联)
        for (NSString *string in self.incomeArray) {
            [self.userDefaults setObject:string forKey:string];
        }
        for (NSString *string in self.expenseArray) {
            [self.userDefaults setObject:string forKey:string];
        }
    }
    // 将incomeType默认为支出
    if (self.incomeType == nil) {
        self.incomeType = @"expense";
    }
}

#pragma mark - date value changed

- (void)datePickerValueDidChanged:(UIDatePicker *)sender {
    // NSDate转NSString
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    self.dateLabel.text = [dateFormatter stringFromDate:sender.date];
}

#pragma mark - picker selected

- (void)pickerSelected {
    self.navigationItem.rightBarButtonItem = nil;
    
    //取消此行的选择状态
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //根据点击的indexPath确定是datePicker还是pickerView
    if (indexPath.row == 1) {
        [self.pickerView removeFromSuperview];
    } else if (indexPath.row == 2) {
        [self.datePicker removeFromSuperview];
    }
    
    //移除遮挡层并销毁
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;

    //恢复左边的保存按钮
    [self.navigationItem.leftBarButtonItem setTitle:@"保存"];
    
    //恢复右边的取消按钮
    [self customizeRightButton];
}

#pragma mark - detail text View delegate methods

//利用delegate方法实现textView的placeholder
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString: @"详细描述(选填)"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    
    // 插入一个透明的夹层View，实现触摸空白区域时返回键盘
    [self insertTransparentView];
    
    [self.shadowView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewResignKeyboard)]];

}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"详细描述(选填)";
        textView.textColor = [UIColor lightGrayColor];
    }
}


#pragma mark - money text field delegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    //插入一个透明的夹层
    [self insertTransparentView];
    [self.shadowView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textFieldResignKeyboard)]];
}


#pragma mark - text view resign first responder
- (void)textViewResignKeyboard {
    [self.detailTextView resignFirstResponder];
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
}

#pragma mark - text field resign first responder
- (void)textFieldResignKeyboard {
    [self.moneyTextField resignFirstResponder];
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
}

#pragma mark - insert a shadow view

// 插入一个透明的夹层View，实现触摸空白区域时返回键盘（tableView不响应touchesbegin等方法）
// 此处将view.alpha设为0后就不能点击了，反而是只初始化的view既透明又能点击
- (void)insertTransparentView {
    self.shadowView = [[UIView alloc] initWithFrame:self.tableView.frame];
    [self.tableView addSubview:self.shadowView];
    [self.tableView bringSubviewToFront:self.shadowView];
}

//插入一个浅灰色的夹层
//此处不选择if (view == nil) {...} 是因为别的地方也要用shadowView，为了防止其上添加各种不同的方法使得复杂，所以每次退出就销毁，进来就用全新的
- (void)insertGrayView {
    self.shadowView = [[UIView alloc] initWithFrame:self.view.frame];
    self.shadowView.backgroundColor = [UIColor grayColor];
    self.shadowView.alpha = 0.5;
    [self.view addSubview:self.shadowView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath.row == 1) {
        [self.view bringSubviewToFront:self.pickerView];
    } else if (indexPath.row == 2) {
        [self.view bringSubviewToFront:self.datePicker];
    }
}

#pragma mark - UIPickerView dataSource

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return 2; // 左侧的需要收入与支出两行
    } else {
        // 根据类型不同提供不同的行数
        if ([self.incomeType isEqualToString:@"income"]) {
            return self.incomeArray.count;
        } else if ([self.incomeType isEqualToString:@"expense"]) {
            return self.expenseArray.count;
        } else {
            return 0;
        }
    }
}

#pragma mark - UIPickerView delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) { // 默认第一行为支出
        if (row == 0) {
            return @"支出";
        } else {
            return @"收入";
        }
    } else {
        // 根据收入支出类型不同分别返回不同的数据
        if ([self.incomeType isEqualToString:@"income"]) {
            return self.incomeArray[row];
        } else {
            return self.expenseArray[row];
        }
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        // 选择不同种类时改变incomeType值，以使得dataSource方法中得以判断右边需要多少行,并改变moneyTextField的字体颜色
        if (row == 0) {
            self.incomeType = @"expense";
            self.moneyTextField.textColor = [UIColor redColor];
        } else {
            self.incomeType = @"income";
            self.moneyTextField.textColor = [UIColor blueColor];
        }
        [self.pickerView reloadComponent:1];
    } else {
        if ([self.incomeType isEqualToString:@"income"]) {
            self.typeLabel.text = self.incomeArray[row];
        } else {
            self.typeLabel.text = self.expenseArray[row];
        }
    }
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
