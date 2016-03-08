//
//  AZXAccountMO.h
//  AZXTallyBook
//
//  Created by azx on 16/3/8.
//  Copyright © 2016年 azx. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface AZXAccountMO : NSManagedObject

@property (nonatomic, strong) NSString *date;

@property (nonatomic, strong) NSString *detail;

@property (nonatomic, strong) NSString *money;

@property (nonatomic, strong) NSString *type;

@property (nonatomic, strong) NSString *incomeType;

- (void)insertNewObjectWithType:(NSString *)type
                         Detail:(NSString *)detail
                          Money:(NSString *)money
                           Date:(NSString *)date
                  AndIncomeType:(NSString *)incomeType;

@end
