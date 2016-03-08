//
//  AZXAccountMO.m
//  AZXTallyBook
//
//  Created by azx on 16/3/8.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXAccountMO.h"

@implementation AZXAccountMO

@dynamic type;
@dynamic detail;
@dynamic money;
@dynamic date;

- (void)insertNewObjectWithType:(NSString *)type
                        Detail:(NSString *)detail
                         Money:(NSString *)money
                       AndDate:(NSString *)date {
    AZXAccountMO *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:[self managedObjectContext]];
    account.type = type;
    account.detail = detail;
    account.money = money;
    account.date = date;
}

@end
