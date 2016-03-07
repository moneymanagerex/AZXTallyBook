//
//  AZXAccount.h
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AZXAccount : NSObject

@property (nonatomic, assign) NSInteger money;

@property (nonatomic, readonly, copy) NSString *type;

@property (nonatomic, readonly, copy) NSString *detail;

@property (nonatomic, readonly, copy) NSString *date;

@end
