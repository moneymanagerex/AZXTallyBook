//
//  AZXSettingTableViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/14.
//  Copyright © 2016年 azx. All rights reserved.
//
/*
    object   Key
    密保问题  questionAZX
    密保答案  answerAZX
    密码使用  useCodeAZX
*/

#import "AZXSettingTableViewController.h"
#import "AZXOperateTypeTableViewController.h"
#import "AppDelegate.h"
#import "Account.h"
#import <CoreData/CoreData.h>

@interface AZXSettingTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *deleteAllLabel;

@property (weak, nonatomic) IBOutlet UISwitch *codeSwitch;

@property (weak, nonatomic) IBOutlet UILabel *changeCode;

@property (weak, nonatomic) IBOutlet UILabel *codeProtectQuestion;

@property (strong, nonatomic) NSUserDefaults *defaults;

@end

@implementation AZXSettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    
    [self judgeFirstLoadThisView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.defaults boolForKey:@"useCodeAZX"]) {
        // 若用户使用密码
        self.changeCode.textColor = [UIColor blueColor];
        self.codeProtectQuestion.textColor = [UIColor blueColor];
        [self.codeSwitch setOn:YES];

    } else {
        // 用户将其设置为关或者是第一次进入应用，密码保护默认为关
        self.codeSwitch.on = NO;
        
        // 密保关闭时，第一个section第2、3个cell都默认不能点击
        if (!self.codeSwitch.isOn) {
            [self cellsInteractionWithSwitchOn:NO];
        }
    }
}

- (void)judgeFirstLoadThisView {
    if (![self.defaults boolForKey:@"haveLoadedAZXSettingTableViewController"]) {
        // 第一次进入此页面
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"教程" message:@"在设置页面你可以开启密码保护，进行类别名称管理" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"知道了，不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.defaults setBool:YES forKey:@"haveLoadedAZXSettingTableViewController"];
        }];
        
        [alert addAction:actionOK];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}

- (IBAction)switchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        self.changeCode.textColor = [UIColor blueColor];
        self.codeProtectQuestion.textColor = [UIColor blueColor];
        // 下面两个cell可以被点击
        [self cellsInteractionWithSwitchOn:YES];
        
        // 弹出对话框输入新密码
        [self alertInputNewCode];
        
        // 将useCodeAZX设为YES，使得下次打开应用时需要输入密码
        [self.defaults setBool:YES forKey:@"useCodeAZX"];
    } else {
        [self returnToSwitchOffStatus];
     
        [self.defaults setBool:NO forKey:@"useCodeAZX"];
    }
}

- (void)cellsInteractionWithSwitchOn:(BOOL)switchIsOn {
    // 打开开关可以点击，关闭开关不能点击
    if (switchIsOn) {
        for (NSInteger i = 1; i < 3; i++) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            cell.userInteractionEnabled = YES;
        }
    } else {
        for (NSInteger i = 1; i < 3; i++) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            cell.userInteractionEnabled = NO;
        }
    }
}

- (void)alertInputNewCode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置" message:@"请输入新密码" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        if ([self.defaults stringForKey:@"codeAZX"]) {
            // 如果以前设置过密码，则显示其上
            textField.text = [self.defaults objectForKey:@"codeAZX"];
        }
    }];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.defaults setObject:alert.textFields[0].text forKey:@"codeAZX"];
        [self askUserToSetCodeProtect];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // 如果取消的话，则恢复到开关关闭的状态
        [self.codeSwitch setOn:NO animated:YES];
        [self returnToSwitchOffStatus];

    }];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)returnToSwitchOffStatus {
    self.changeCode.textColor = [UIColor lightGrayColor];
    self.codeProtectQuestion.textColor = [UIColor lightGrayColor];
    // 下面两个cell不能被点击
    [self cellsInteractionWithSwitchOn:NO];
}

- (void)askUserToSetCodeProtect {
    UIAlertController *whetherSetCodeProtect = [UIAlertController alertControllerWithTitle:@"提示" message:@"设置密码保护问题可以使您在忘记密码时找回密码" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *yes = [UIAlertAction actionWithTitle:@"现在设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setUpCodeProtectQuestion];
    }];
    
    UIAlertAction *no = [UIAlertAction actionWithTitle:@"以后再说" style:UIAlertActionStyleCancel handler:nil];
    
    [whetherSetCodeProtect addAction:no];
    [whetherSetCodeProtect addAction:yes];
    
    [self presentViewController:whetherSetCodeProtect animated:YES completion:nil];

}

- (void)setUpCodeProtectQuestion {
    __block UIAlertController *addProtectQuestion = [UIAlertController alertControllerWithTitle:@"设置" message:@"输入问题及答案" preferredStyle:UIAlertControllerStyleAlert];
    [addProtectQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"设置问题";
    }];
    [addProtectQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"设置答案";
    }];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (addProtectQuestion.textFields[0].text != nil && addProtectQuestion.textFields[1].text != nil) {
            // 如果都输入了内容，将问题与答案保存起来
            [self.defaults setObject:addProtectQuestion.textFields[0].text forKey:@"questionAZX"];
            [self.defaults setObject:addProtectQuestion.textFields[1].text forKey:@"answerAZX"];
        } else {
            UIAlertController *remainder = [UIAlertController alertControllerWithTitle:@"提示" message:@"问题与答案都不能为空" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *enterAgain = [UIAlertAction actionWithTitle:@"再次输入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self setUpCodeProtectQuestion];
            }];
            
            UIAlertAction *quit = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            
            [remainder addAction:quit];
            [remainder addAction:enterAgain];
            
            [self presentViewController:remainder animated:YES completion:nil];
        }
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];

    [addProtectQuestion addAction:actionCancel];
    [addProtectQuestion addAction:actionOK];
    
    [self presentViewController:addProtectQuestion animated:YES completion:nil];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else if (section == 1) {
        return 3;
    } else {
        return 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.codeSwitch.isOn && indexPath.section == 0 && indexPath.row == 1) {
        // 开关打开并点击修改密码
        [self alertChangeCode];
    } else if (self.codeSwitch.isOn && indexPath.section == 0 && indexPath.row == 2) {
        [self changeProtectQuestion];
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        // 清除所有数据
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"全部数据删除后将无法找回" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self deleteAllAccounts];
        }];
        
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:actionCancel];
        [alert addAction:actionOK];
        
        [self presentViewController:alert animated:YES completion:^ {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    }
}

- (void)deleteAllAccounts {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    NSError *error = nil;
    NSArray *allAccounts = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
    
    // 将所有account删除
    for (Account *account in allAccounts) {
        [appDelegate.managedObjectContext deleteObject:account];
    }
}


#pragma mark - change Code and protect question methods

- (void)alertChangeCode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置" message:@"请输入旧的密码，以验证身份" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([alert.textFields[0].text isEqualToString:[self.defaults objectForKey:@"codeAZX"]]) {
            // 旧密码正确，则输入新密码
            [self enterNewCode];
        } else {
            // 旧密码错误
            [self wrongOldCode];
        }
    }];
    
    UIAlertAction *actionForget = [UIAlertAction actionWithTitle:@"忘记密码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 忘记密码，弹出密保问题
        [self showProtectQuestion];
    }];
    
    [alert addAction:actionForget];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)enterNewCode {
    // 用来比较两次输入新密码是否一样
    __block NSString *tmpNewCode = [NSString string];
    
    // 输入新密码
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置" message:@"请输入新密码" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        tmpNewCode = alert.textFields[0].text;
        // 再次输入密码
        [self enterNewCodeAgainWithCode:tmpNewCode];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];

    
    
}

- (void)enterNewCodeAgainWithCode:(NSString *)tmpNewCode {
    // 再次输入密码
    
    UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"设置" message:@"再次输入新密码" preferredStyle:UIAlertControllerStyleAlert];
    [alert2 addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *actionOK2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([alert2.textFields[0].text isEqualToString:tmpNewCode]) {
            // 如果两次密码相同，保存密码
            [self.defaults setObject:tmpNewCode forKey:@"codeAZX"];
            // 弹窗显示修改成功
            [self changeSuccessfully];
        } else {
            // 两次密码输入不相同
            UIAlertController *alertWrong = [UIAlertController alertControllerWithTitle:@"提示" message:@"两次输入密码必须相同" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *enterAgain = [UIAlertAction actionWithTitle:@"再次输入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // 递归调用enterNewCode函数，再次输入
                [self enterNewCode];
            }];
            
            [alertWrong addAction:cancel];
            [alertWrong addAction:enterAgain];
            
            [self presentViewController:alertWrong animated:YES completion:nil];
        }
    }];
    
    UIAlertAction *actionCancel2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert2 addAction:actionCancel2];
    [alert2 addAction:actionOK2];
    
    [self presentViewController:alert2 animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
    
}

- (void)wrongOldCode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"密码错误，请重试" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"再次输入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 点击重试，再次弹出修改密码对话框
        [self alertChangeCode];
    }];
    
    UIAlertAction *actionForget = [UIAlertAction actionWithTitle:@"忘记密码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 忘记密码，则弹出密码保护问题
        [self showProtectQuestion];
    }];
    
    [alert addAction:actionForget];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showProtectQuestion {
    UIAlertController *question = [UIAlertController alertControllerWithTitle:@"输入答案" message:[NSString stringWithFormat:@"%@", [self.defaults objectForKey:@"questionAZX"]] preferredStyle:UIAlertControllerStyleAlert];
    
    [question addTextFieldWithConfigurationHandler:nil];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([question.textFields[0].text isEqualToString:[self.defaults objectForKey:@"answerAZX"]]) {
            // 如果答案正确，让用户设置新密码
            [self enterNewCode];
        } else {
            // 否则弹出错误提示
            [self wrongAnswer];
        }
    }];
    
    UIAlertAction *no = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [question addAction:no];
    [question addAction:ok];
    
    [self presentViewController:question animated:YES completion:nil];
}

- (void)wrongAnswer {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"答案错误，请重试" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"再次输入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 点击重试，再次弹出密保问题对话框
        [self showProtectQuestion];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
    
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];

}


- (void)changeSuccessfully {
    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"" message:@"修改成功" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    
    [success addAction:ok];
    
    [self presentViewController:success animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];

}

- (void)changeProtectQuestion {
    UIAlertController *changeQuestion = [UIAlertController alertControllerWithTitle:@"设置" message:@"修改问题与答案" preferredStyle:UIAlertControllerStyleAlert];
    
    // 默认显示问题与答案
    [changeQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [self.defaults objectForKey:@"questionAZX"];
    }];
    [changeQuestion addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [self.defaults objectForKey:@"answerAZX"];
    }];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.defaults setObject:changeQuestion.textFields[0].text forKey:@"questionAZX"];
        [self.defaults setObject:changeQuestion.textFields[1].text forKey:@"answerAZX"];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [changeQuestion addAction:actionCancel];
    [changeQuestion addAction:actionOK];
    
    [self presentViewController:changeQuestion animated:YES completion:^ {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addOrDeleteType"]) {
        // 如果是添加或删除类别
        AZXOperateTypeTableViewController *viewController = [segue destinationViewController];
        viewController.operationType = @"addOrDeleteType";
    } else if ([segue.identifier isEqualToString:@"changeType"]) {
        // 如果是重命名类别
        AZXOperateTypeTableViewController *viewController = [segue destinationViewController];
        viewController.operationType = @"changeType";
    } else if ([segue.identifier isEqualToString:@"moveType"]) {
        // 如果是移动类别位置
        AZXOperateTypeTableViewController *viewController = [segue destinationViewController];
        viewController.operationType = @"moveType";
    }
}


@end
