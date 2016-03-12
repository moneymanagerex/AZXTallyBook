//
//  AZXPieView.m
//  AZXTallyBook
//
//  Created by azx on 16/3/12.
//  Copyright © 2016年 azx. All rights reserved.
//

#import "AZXPieView.h"

IB_DESIGNABLE
@implementation AZXPieView

- (void)drawRect:(CGRect)rect {
    // 先将背景色设为默认
    [[UIColor whiteColor] set];
    UIRectFill(rect);


    
}

- (void)drawSectorWithStartAngle:(CGFloat)startAngle Percent:(CGFloat)percent Type:(NSString *)type Color:(UIColor *)color {
    CGFloat radius = self.frame.size.width > self.frame.size.height? self.frame.size.height/2 : self.frame.size.width/2;  // 半径取矩形短的一边
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:self.center radius:radius startAngle:startAngle endAngle:startAngle + 2*M_PI*percent clockwise:YES];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    // 找到扇形中心点
    CGFloat centerX = self.center.x + (radius/2*cos(M_PI*percent));
    CGFloat centerY = self.center.y + (radius/2*sin(M_PI*percent));
    
    label.center = CGPointMake(centerX, centerY);
    
    label.text = type;
    
    label.textColor = [UIColor whiteColor];
    
    label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    
    label.textAlignment = NSTextAlignmentCenter;
    
    [label sizeToFit];
    
    [self addSubview:label];
    
    [color set];
    [path fill];

}

@end
