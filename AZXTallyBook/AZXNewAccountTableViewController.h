//
//  AZXNewAccountTableViewController.h
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AZXNewAccountTableViewController;

@protocol PassingDateDelegate <NSObject>;
@optional
- (void)viewController:(AZXNewAccountTableViewController *)controller didPassDate:(NSString *)date;
// 使用代理将date值传给首页(让其筛选Fetch的managedObject)
@end

@interface AZXNewAccountTableViewController : UITableViewController

@property (nonatomic, weak) id<PassingDateDelegate> delegate;

@end
