//
//  AZXAccountViewController.h
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

// 这个Controller

#import <UIKit/UIKit.h>

@interface AZXAccountViewController : UIViewController

@property (nonatomic, strong) NSString *passedDate; // 从别处传来的date值，用做Predicate筛选Fetch的ManagedObject
@end
