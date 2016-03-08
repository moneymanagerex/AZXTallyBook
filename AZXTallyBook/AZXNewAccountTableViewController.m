//
//  AZXNewAccountTableViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXNewAccountTableViewController.h"
#import "AZXAccountMO.h"

@interface AZXNewAccountTableViewController () <UITextViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *moneyTextField;

@property (weak, nonatomic) IBOutlet UILabel *typeLabel;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UITextView *detailTextView; //详细描述

@property (strong, nonatomic) UIDatePicker *datePicker; //日期选择器

@property (strong, nonatomic) UIBarButtonItem *doneButton;

@property (strong, nonatomic) UIView *shadowView; // 插入的灰色夹层

@end

@implementation AZXNewAccountTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //日期显示默认为当前日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    self.dateLabel.text = [dateFormatter stringFromDate:[NSDate date]];
    
    // 自定义返回按钮
    [self customizeBackButton];
    
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

#pragma mark - customize back button

- (void)customizeBackButton {
    //UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    // 将button的文字改为日期
    //[button setTitle:self.dateLabel.text forState:UIControlStateNormal];
    // 设置返回按钮的触发事件
    //[button addTarget:self action:@selector(backBarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    //UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(backBarButtonPressed:)];
    //UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(backBarButtonPressed:)];
    self.navigationItem.leftBarButtonItem = backItem;
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
        AZXAccountMO *account = [[AZXAccountMO alloc] init];
        [account insertNewObjectWithType:self.typeLabel.text
                                  Detail:self.detailTextView.text
                                   Money:self.moneyTextField.text
                                 AndDate:self.dateLabel.text];
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
        
        //插入一个浅灰色的夹层
        [self insertGrayView];
        
        //点击datePicker外的灰色夹层也视为确认日期
        [self.shadowView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dateSelected)]];
        
        //导航栏右边添加“完成”按钮
        if (self.doneButton == nil) {
            self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(dateSelected)];
        }
        self.navigationItem.rightBarButtonItem = self.doneButton;
        // 并将左边的保存按钮暂时隐藏起来
        [self.navigationItem.leftBarButtonItem setTitle:@""];
        
        //添加监听事件
        [self.datePicker addTarget:self action:@selector(datePickerValueDidChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

#pragma mark - date value changed

- (void)datePickerValueDidChanged:(UIDatePicker *)sender {
    // NSDate转NSString
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    self.dateLabel.text = [dateFormatter stringFromDate:sender.date];
}

#pragma mark - date selected

- (void)dateSelected {
    self.navigationItem.rightBarButtonItem = nil;
    [self.datePicker removeFromSuperview];
    
    //移除遮挡层并销毁
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
    
    //取消此行的选择状态
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

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
    [self.view bringSubviewToFront:self.datePicker];
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
