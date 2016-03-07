//
//  AZXAccount.m
//  AZXTallyBook
//
//  Created by azx on 16/2/21.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXAccount.h"

@implementation AZXAccount

- (instancetype)init
{
    if (self = [super init]) {
        _money = 0;
        _type = @"";
        _detail = @"";
        _date = @"";
    }
    return self;
}

@end
