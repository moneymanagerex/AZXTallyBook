//
//  AZXOperateTypeTableViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/14.
//  Copyright © 2016年 azx. All rights reserved.
//
/*
 object      Key
 收入类型组   incomeAZX
 支出类型组   expenseAZX
 
 */

#import "AZXOperateTypeTableViewController.h"
#import "AZXOperateTypeTableViewCell.h"
#import "AppDelegate.h"
#import "Account.h"
#import <CoreData/CoreData.h>

@interface AZXOperateTypeTableViewController ()

@property (nonatomic, strong) NSMutableArray *typeArray;

@property (nonatomic, strong) NSString *incomeType;

@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation AZXOperateTypeTableViewController

- (NSString *)incomeType {
    if (!_incomeType) {
        _incomeType = @"expense"; // 默认为支出
    }
    return _incomeType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 将要退出界面时，将数组数据保存
    NSLog(@"保存%@", self.typeArray);
    [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
}

- (IBAction)segControlChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
        
        [self refreshAll];
        [self.tableView reloadData];
    } else {
        self.incomeType = @"income";
        
        [self refreshAll];
        [self.tableView reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshAll];

}

- (void)refreshAll {
    // 取得储存的支出/收入类型数组
    if ([self.incomeType isEqualToString:@"income"]) {
        // objectForKey总是返回不可变的对象(即使存进去的时候是可变的)
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"incomeAZX"]];
    } else {
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"expenseAZX"]];
    }
    
    // 若为删除/添加操作，则右上角加一个添加按钮
    if ([self.operationType isEqualToString:@"addOrDeleteType"]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:self action:@selector(addType)];
    } else if ([self.operationType isEqualToString:@"moveType"]) {
        [self.tableView setEditing:YES animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.typeArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AZXOperateTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"operateTypeCell" forIndexPath:indexPath];
    
    cell.type.text = self.typeArray[indexPath.row];
    
    if ([self.operationType isEqualToString:@"addOrDeleteType"]) {
        // 进行加减操作，为删除label添加点击事件
        cell.operation.text = @"删除";
        cell.operation.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tapLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDelete:)];
        
        [cell.operation addGestureRecognizer:tapLabel];
        
    } else if ([self.operationType isEqualToString:@"changeType"]) {
        // 进行重命名操作
        cell.operation.text = @"重命名";
        cell.operation.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tapLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRename:)];
        
        [cell.operation addGestureRecognizer:tapLabel];

        
    } else if ([self.operationType isEqualToString:@"moveType"]) {
        // 进行排序操作
        cell.operation.text = @"按住拖动";
        
    }
    
    return cell;
}

#pragma mark - Add or delete methods

- (void)addType {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加类别" message:@"输入新类别名称" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"点击输入";
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 新加入类型保存起来并刷新tableView
        [self.typeArray addObject:alert.textFields[0].text];
        [self.tableView reloadData];
        // 保存数据
        [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)tapDelete:(UITapGestureRecognizer *)gesture {
    // 通过点击位置确定点击的cell位置
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"确定删除\"%@\"?", self.typeArray[indexPath.row]] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 将要删除的类别名与图片名称的关联除去
        [self.defaults removeObjectForKey:self.typeArray[indexPath.row]];

        // 将所有此类别的账单一并移去
        [self removeAllAccountOfOneType:self.typeArray[indexPath.row]];
        
        // 将其移除
        [self.typeArray removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];        
        
        // 保存数据
        [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)removeAllAccountOfOneType:(NSString *)type {
    // 删除所有此类别的account
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"type == %@", type]];

    NSError *error = nil;
    NSArray *accounts = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    for (Account *account in accounts) {
        [self.managedObjectContext deleteObject:account];
    }
}

#pragma mark - Rename methods

- (void)tapRename:(UITapGestureRecognizer *)gesture {
    // 通过点击位置确定点击的cell位置
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改名称" message:@"请输入新类别名称" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = self.typeArray[indexPath.row];
    }];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 保存在Assets中的图片的名称
        NSString *imageName = [self.defaults objectForKey:self.typeArray[indexPath.row]];
        
        // 将旧的类别名与图片名称的关联除去
        [self.defaults removeObjectForKey:self.typeArray[indexPath.row]];
        
        // 将新的类别名与图片名称相关联
        [self.defaults setObject:imageName forKey:alert.textFields[0].text];
        
        // 修改数组中存放的类别名称
        self.typeArray[indexPath.row] = alert.textFields[0].text;
        
        // 刷新tableView
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // 保存数据
        [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}


#pragma mark - Move tableView delegate methods

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.operationType isEqualToString:@"moveType"]) {
        return YES;
    } else {
        return NO;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    // 需要移动的行
    NSString *typeToMove = self.typeArray[fromIndexPath.row];
    
    [self.typeArray removeObjectAtIndex:fromIndexPath.row];
    [self.typeArray insertObject:typeToMove atIndex:toIndexPath.row];
    
    // 保存数据
    [self.defaults setObject:self.typeArray forKey:[self.incomeType stringByAppendingString:@"AZX"]];
}

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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
