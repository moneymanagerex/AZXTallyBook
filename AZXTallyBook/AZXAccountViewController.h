//
//  AZXAccountViewController.h
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

// 这个Controller有两个不同的UI(有按钮、无按钮)

#import <UIKit/UIKit.h>

@interface AZXAccountViewController : UIViewController

@property (nonatomic, strong) NSString *passedDate; // 从别处传来的date值，用做Predicate筛选Fetch的ManagedObject

@property (nonatomic, strong) NSString *selectedType; // 若从统计的类别处传来，则一进入界面就选中该类型的行

@end
