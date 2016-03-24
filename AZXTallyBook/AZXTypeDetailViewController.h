//
//  AZXTypeDetailViewController.h
//  AZXTallyBook
//
//  Created by azx on 16/3/14.
//  Copyright © 2016年 azx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AZXTypeDetailViewController : UIViewController

// 接收要显示哪一个月的哪一种类型的支出/收入
@property (nonatomic, strong) NSString *date;

@property (nonatomic, strong) NSString *type;

@property (nonatomic, strong) NSString *incomeType;

@end
