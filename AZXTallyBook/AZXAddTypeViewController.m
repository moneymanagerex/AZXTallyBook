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

@property (strong, nonatomic) NSMutableArray *typeArray; // 存放各种类别

@property (strong, nonatomic) NSUserDefaults *defaults;

@property (strong, nonatomic) NSString *incomeType;

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
    
    [self.typeTextField becomeFirstResponder];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(rightBarItemPressed)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 取得支出收入的所有类型
    self.typeArray = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"expenseAZX"]];
    self.typeArray = [NSMutableArray arrayWithArray:[self.typeArray arrayByAddingObjectsFromArray:[self.defaults objectForKey:@"incomeAZX"]]];
}

- (void)rightBarItemPressed {
    // 若两者都已输入，将图片与类别名保存并联系起来
    if (self.typeTextField.text && self.showImage.image) {
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
    if (self.typeTextField.text && self.showImage.image) {
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
    }
}

- (void)savePhotoFromAlbum {
    NSData *data;
    if (UIImagePNGRepresentation(self.selectedPhoto) == nil) {
        // 如果不是PNG格式，则用JPEG储存
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
    
    //把刚刚图片转换的data对象拷贝至沙盒中 并保存为image.png
    [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:@"/image.png"] contents:data attributes:nil];
    
    //得到选择后沙盒中图片的完整路径
//    NSString *filePath = [[NSString alloc]initWithFormat:@"%@%@",DocumentsPath,  @"/image.png"];

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
    // 得到相应类型的图片，其中保存在Assets中的图片名由userDefaults取得
    cell.image.image = [UIImage imageNamed:[self.defaults objectForKey:self.typeArray[indexPath.row]]];
    
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndexOfImage) {
        // 如果之前存在被选中的item
        AZXAddTypeCollectionViewCell *cell = (AZXAddTypeCollectionViewCell *)[self.typeCollectionView cellForItemAtIndexPath:self.selectedIndexOfImage];
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    AZXAddTypeCollectionViewCell *cell = (AZXAddTypeCollectionViewCell *)[self.typeCollectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor lightGrayColor];
    
    // 将新的item的indexPath设为已选择
    self.selectedIndexOfImage = indexPath;
    
    self.showImage.image = cell.image.image; // 显示选中的图片
    
    // 设为从已有图片选择
    self.isFromAlbum = NO;
    
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalWidth = self.typeCollectionView.frame.size.width;
    CGFloat totalHeight = self.typeCollectionView.frame.size.height;
    // cell为正方形，检验一行4个cell是否会超出collectionView的范围(事实上超出也没事，只是我无法处理因为cell重用导致的cell滑出界面后出现的选中背景色随机出现在各个cell上的问题)
    // 如果一行4个会超出，则一行加一个，直至不会超出
    int columns = 4;
    // 计算可以容纳的行数
    int rows = (int)totalHeight / (totalWidth / (columns + 1));
    while (rows * columns < self.typeArray.count) {
        // 如果不能容纳，则列数加一
        columns++;
        rows = (int)totalHeight / (totalWidth / (columns + 1));
    }
    return CGSizeMake(totalWidth / columns , totalWidth / columns);
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
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
