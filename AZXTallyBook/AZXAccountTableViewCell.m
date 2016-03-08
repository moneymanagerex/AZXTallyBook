//
//  AZXAccountTableViewCell.m
//  AZXTallyBook
//
//  Created by azx on 16/3/7.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXAccountTableViewCell.h"

@implementation AZXAccountTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.typeImage.image = [UIImage imageNamed:self.typeName.text]; // 图片采用名称为typeName的本地图片
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
