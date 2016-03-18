//
//  AZXAddTypeViewController.m
//  AZXTallyBook
//
//  Created by azx on 16/3/16.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXAddTypeViewController.h"
#import "AZXAddTypeCollectionViewCell.h"
#import "UIViewController+BackButtonHandler.h"

@interface AZXAddTypeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *typeCollectionView;

@property (weak, nonatomic) IBOutlet UIImageView *showImage;

@property (weak, nonatomic) IBOutlet UITextField *typeTextField;

@property (strong, nonatomic) NSMutableArray *typeArray; // 存放各种类别名称(用来显示collectionView中图片的数据源)

@property (strong, nonatomic) NSUserDefaults *defaults;

@property (strong, nonatomic) NSString *incomeType;

@property (strong, nonatomic) NSMutableArray *incomeArray; // 收入类别数组

@property (strong, nonatomic) NSMutableArray *expenseArray; // 支出类别数组

@property (strong, nonatomic) UIView *shadowView; // 实现点击空白区域返回键盘的隔层

@property (weak, nonatomic) IBOutlet UIButton *localPhotoButton; // 打开本地相册

@property (strong, nonatomic) UIImage *selectedPhoto; // 从相册里选择的图片

@property (strong, nonatomic) NSIndexPath *selectedIndexOfImage; // 选中的屏幕上的图片

@property (assign, nonatomic) BOOL isFromAlbum; // 最后保存时是从相册选择的还是从已有的图片选择，YES代表从相册里选择
@end

@implementation AZXAddTypeViewController
- (NSString *)incomeType {
    if (!_incomeType) {
        _incomeType = @"expense"; // 收支类型默认为支出
    }
    return _incomeType;
}

- (IBAction)typeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.incomeType = @"expense";
    } else {
        self.incomeType = @"income";
    }
}

// 打开相册
- (IBAction)localPhoto:(UIButton *)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        // 如果相册可用
        UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
        photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        photoPicker.delegate = self;
        //设置选择后的图片可被编辑
        photoPicker.allowsEditing = YES;
        
        // 设置其弹出方式(自动适配iPad和iPhone)
        photoPicker.modalPresentationStyle = UIModalPresentationPopover;
        
        [self presentViewController:photoPicker animated:YES completion:nil];
        
        // 获取popoverPresentationController
        UIPopoverPresentationController *presentationController = [photoPicker popoverPresentationController];
        
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.sourceView = self.localPhotoButton;
        presentationController.sourceRect = self.localPhotoButton.bounds;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.typeCollectionView.delegate = self;
    self.typeCollectionView.dataSource = self;
    self.typeTextField.delegate = self;
    
    self.typeCollectionView.backgroundColor = [UIColor whiteColor];
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    
    // 一进入界面就弹出键盘
    [self.typeTextField becomeFirstResponder];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(rightBarItemPressed)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 取得支出收入的所有类型
    self.expenseArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"expenseAZX"]];
    self.incomeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"incomeAZX"]];
    
    if (![self.defaults objectForKey:@"imagesShowInAZXAddTypeViewController"]) {
        // 如果还未保存显示在这界面的图片数组
        self.typeArray = [NSMutableArray arrayWithArray:@[@"餐饮食品", @"交通路费", @"日常用品", @"服装首饰", @"学习教育", @"烟酒消费", @"房租水电", @"网上购物", @"运动健身", @"电子产品", @"化妆护理", @"医疗体检", @"游戏娱乐", @"外出旅游", @"油费维护", @"慈善捐赠", @"其他支出", @"工资薪酬", @"奖金福利", @"生意经营", @"投资理财", @"彩票中奖", @"银行利息", @"其他收入"]];
        [self.defaults setObject:self.typeArray forKey:@"imagesShowInAZXAddTypeViewController"];
    } else {
        self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"imagesShowInAZXAddTypeViewController"]];
    }
}

- (void)rightBarItemPressed {
    // 首先判断是否新类别名已存在，不允许重复
    if ([self.expenseArray containsObject:self.typeTextField.text] || [self.incomeArray containsObject:self.typeTextField.text]) {
        [self popoverAlertControllerWithMessage:@"类别名已存在，请使用新的类别名"];
    } else if (self.typeTextField.text && self.showImage.image) {
        // 若两者都已输入，将图片与类别名保存并联系起来
        [self savePhotoWithTypeName];
        
        // 跳回上一界面
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // 弹出提示
        [self popoverAlertControllerWithMessage:@"图片与类别名都需要输入"];
    }
}

- (void)popoverAlertControllerWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// 点击back按钮后调用 引用的他人写的一个extension
- (BOOL)navigationShouldPopOnBackButton {
    if (![self.typeTextField.text isEqualToString:@""] && self.showImage.image) {
        // 当二者都填上内容时，点击返回询问是否保存
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"还未保存，是否返回？" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *OK = [UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:cancel];
        [alert addAction:OK];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return NO;
    }
    return YES;
}

// 将图片与类别名关联并保存
- (void)savePhotoWithTypeName {
    if (self.isFromAlbum) {
        // 如果是从相册中选择的
        [self savePhotoFromAlbum];
    } else {
        // 如果是从已有的图片中选择的
        NSInteger index = [self.typeCollectionView indexPathsForSelectedItems][0].row;
        // 图片的名称(路径)
        NSString *imageName = self.typeArray[index];
        // 将二者关联起来
        [self.defaults setObject:imageName forKey:self.typeTextField.text];
    }
}

- (void)savePhotoFromAlbum {
    NSData *data;
    if (UIImagePNGRepresentation(self.selectedPhoto) == nil) {
        data = UIImageJPEGRepresentation(self.selectedPhoto, 1.0);
    }
    else {
        data = UIImagePNGRepresentation(self.selectedPhoto);
    }
    
    //图片保存的路径
    //这里将图片放在沙盒的documents文件夹中
    NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    //文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 新类别名
    NSString *type = self.typeTextField.text;
    
    //把刚刚图片转换的data对象拷贝至沙盒中 并保存为 类别名.png
    [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.png", type]] contents:data attributes:nil];
    
    //得到选择后沙盒中图片的完整路径
    NSString *filePath = [[NSString alloc]initWithFormat:@"%@%@",DocumentsPath, [NSString stringWithFormat:@"/%@.png", type]];

    
    // 将类别名与图片的储存路径关联起来，到时候取出图片时直接用[imageNamed:储存路径]方法
    [self.defaults setObject:filePath forKey:type];
    
    // 将类别名加入相应的类别数组
    if ([self.incomeType isEqualToString:@"income"]) {
        [self.incomeArray addObject:type];
        [self.defaults setObject:self.incomeArray forKey:@"incomeAZX"];
    } else {
        [self.expenseArray addObject:type];
        [self.defaults setObject:self.expenseArray forKey:@"expenseAZX"];
    }
    
    // 并将新加入的图片保存在此页面的typeArray，下次进入界面就会显示出来
    [self.typeArray addObject:filePath];
    [self.defaults setObject:self.typeArray forKey:@"imagesShowInAZXAddTypeViewController"];
}

#pragma mark - textField delegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    //插入一个透明的夹层
    [self insertTransparentView];
    [self.shadowView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textFieldResignKeyboard)]];
}

- (void)insertTransparentView {
    self.shadowView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.shadowView];
    [self.view bringSubviewToFront:self.shadowView];
}

- (void)textFieldResignKeyboard {
    [self.typeTextField resignFirstResponder];
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.typeArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AZXAddTypeCollectionViewCell *cell = [self.typeCollectionView dequeueReusableCellWithReuseIdentifier:@"typeImageCell" forIndexPath:indexPath];
    // 得到相应名称(路径)的图片，
    cell.image.image = [UIImage imageNamed:self.typeArray[indexPath.row]];
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [UIColor lightGrayColor];
    
    cell.selectedBackgroundView = backgroundView;
    
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AZXAddTypeCollectionViewCell *cell = (AZXAddTypeCollectionViewCell *)[self.typeCollectionView cellForItemAtIndexPath:indexPath];
    
    // 显示选中的图片
    self.showImage.image = cell.image.image;
    
    // 设为从已有图片选择
    self.isFromAlbum = NO;
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalWidth = self.typeCollectionView.frame.size.width;

    // 一行显示4个cell
    return CGSizeMake(totalWidth / 4 , totalWidth / 4);
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^ {
        // 如果之前屏幕上有选中的图片，将屏幕上被选中的cell给deselect掉
        if ([self.typeCollectionView indexPathsForSelectedItems].count != 0) {
            [self.typeCollectionView deselectItemAtIndexPath:[self.typeCollectionView indexPathsForSelectedItems][0] animated:YES];
        }
    }];
    
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([type isEqualToString:@"public.image"]) {
        // 当选择的类型是图片时，显示在小imageView上
        self.selectedPhoto = [info objectForKey:@"UIImagePickerControllerEditedImage"];
       
        self.showImage.image = self.selectedPhoto;
    }
    
    // 设为从相册选择
    self.isFromAlbum = YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
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
