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
@dynamic incomeType;

- (void)insertNewObjectWithType:(NSString *)type
                         Detail:(NSString *)detail
                          Money:(NSString *)money
                           Date:(NSString *)date
                  AndIncomeType:(NSString *)incomeType{
    AZXAccountMO *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:[self managedObjectContext]];
//    account.type = type;
//    account.detail = detail;
//    account.money = money;
//    account.date = date;
//    account.incomeType = incomeType;
    [account setValue:type forKey:@"type"];
    [account setValue:detail forKey:@"detail"];
    [account setValue:money forKey:@"money"];
    [account setValue:date forKey:@"date"];
    [account setValue:incomeType forKey:@"incomeType"];

}

@end
