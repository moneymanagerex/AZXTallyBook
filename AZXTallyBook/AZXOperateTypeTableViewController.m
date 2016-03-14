//
//  AZXOperateTypeTableViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/14.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXOperateTypeTableViewController.h"
#import "AZXOperateTypeTableViewCell.h"

@interface AZXOperateTypeTableViewController ()

@property (nonatomic, strong) NSMutableArray *typeArray;

@property (nonatomic, strong) NSString *incomeType;

@property (nonatomic, strong) NSUserDefaults *defaults;

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
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 将要退出界面时，将数组数据保存
    [self.defaults setObject:self.typeArray forKey:self.incomeType];
}

- (IBAction)segControlChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
    } else {
        self.incomeType = @"income";
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 取得储存的支出/收入类型数组
    if ([self.incomeType isEqualToString:@"income"]) {
        // objectForKey总是返回不可变的对象(即使存进去的时候是可变的)
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"income"]];
    } else {
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"expense"]];
    }
    
    // 若为删除/添加操作，则右上角加一个添加按钮
    if ([self.operationType isEqualToString:@"addOrDeleteType"]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:self action:@selector(addType)];
    }
}

- (void)addType {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加类别" message:@"输入新类别名称" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"点击输入";
    }];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 新加入类型保存起来并刷新tableView
        [self.typeArray addObject:alert.textFields[0].text];
        [self.tableView reloadData];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
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
    } else if ([self.operationType isEqualToString:@"moveType"]) {
        // 进行排序操作
        cell.operation.text = @"长按拖动";
    }
    
    return cell;
}

- (void)tapDelete:(UITapGestureRecognizer *)gesture {
    // 通过点击位置确定点击的cell位置
    NSInteger index = (NSInteger)[gesture locationInView:self.tableView].y / 44;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"确定删除\"%@\"?", self.typeArray[index]] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 将其移除
        [self.typeArray removeObjectAtIndex:index];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:YES];
    }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:actionCancel];
    [alert addAction:actionOK];
    
    [self presentViewController:alert animated:YES completion:nil];
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
