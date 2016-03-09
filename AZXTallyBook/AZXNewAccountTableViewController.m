//
//  AZXNewAccountTableViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXNewAccountTableViewController.h"
#import "Account.h"
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

- (void)viewDidLoad {
    [super viewDidLoad];

    //日期显示默认为当前日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    self.dateLabel.text = [dateFormatter stringFromDate:[NSDate date]];
    
    // 自定义返回按钮
    [self customizeLeftButton];
    
    //利用textView的delegate实现其placeholder
    self.detailTextView.delegate = self;
    self.detailTextView.text = @"详细描述(选填)";
    self.detailTextView.textColor = [UIColor lightGrayColor];
    
    
    //一进入界面即弹出弹出输入金额
    [self.moneyTextField becomeFirstResponder];
    self.moneyTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.moneyTextField.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 视图消失时，判断是否有代理且实现了代理方法
    // 若实现了，将date传过去
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewController:didPassDate:)]) {
        [self.delegate viewController:self didPassDate:self.dateLabel.text];
    }
    
}

#pragma mark - customize left button

- (void)customizeLeftButton {
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"<保存" style:UIBarButtonItemStylePlain target:self action:@selector(backBarButtonPressed:)];
    
    self.navigationItem.leftBarButtonItem = leftItem;
}

- (void)backBarButtonPressed:(UIButton *)sender {
    if ([self.typeLabel.text isEqualToString:@"type"] || [self.moneyTextField.text  isEqualToString:@"0"]) {
        // type和money都是必填的，如果有一个没填，则弹出AlertController提示
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"金钱数额和类型都是必填的" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
        
        [alertController addAction:action];
        
        // 弹出alertController之前先将所有的键盘收回，否则会导致之后键盘不响应
        [self.moneyTextField resignFirstResponder];
        [self.detailTextView resignFirstResponder];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        // 若是必填项都已填好，则将属性保存在CoreData中
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        
        //NSEntityDescription *entity = [NSEntityDescription entityForName:@"Account" inManagedObjectContext:[appDelegate managedObjectContext]];
        
        //Account *account = [[Account alloc] initWithEntity:entity insertIntoManagedObjectContext:[appDelegate managedObjectContext]];

        Account *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:appDelegate.managedObjectContext];
        
        account.type = self.typeLabel.text;
        account.detail = self.detailTextView.text;
        account.money = self.moneyTextField.text;
        account.incomeType = self.incomeType;
        account.date = self.dateLabel.text;
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
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
    // 创建userDefault单例对象
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    // 从userDefault中获取数据
    self.incomeArray = [self.userDefaults objectForKey:@"income"];
    self.expenseArray = [self.userDefaults objectForKey:@"expense"];
    
    if (self.incomeArray.count == 0 || self.expenseArray.count == 0) {
        //若第一次进入应用，则为其设置默认的收入支出种类
        self.incomeArray = [NSMutableArray arrayWithArray:@[@"工资薪酬", @"奖金福利", @"生意经营", @"金融投资", @"彩票中奖", @"银行利息", @"其他收入"]];
        self.expenseArray = [NSMutableArray arrayWithArray:@[@"日常餐饮", @"外出聚餐", @"交通路费", @"日常用品", @"服装首饰", @"学习教育", @"烟酒消费", @"房租水电", @"运动健身", @"电子产品", @"化妆用品", @"医疗体检", @"外出旅游", @"其他消费"]];
        
        // 保存至userDefaults中
        [self.userDefaults setObject:self.incomeArray forKey:@"income"];
        [self.userDefaults setObject:self.expenseArray forKey:@"expense"];
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
            self.moneyTextField.textColor = [UIColor greenColor];
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
