//
//  StarView.m
//  Chao Co Viet Nam
//
//  Created by Son Dao Hoang on 11/8/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import "StarView.h"

@implementation StarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat centerX = rect.size.width / 2;
    CGFloat centerY = rect.size.height / 2;
    CGFloat radius;
    CGFloat ratio = rect.size.width / rect.size.height;
    
    if (ratio < 0.666)
    {
        // portrait mode
        // radius = 3/10 of the height
        radius = rect.size.height * 0.3;
    }
    else
    {
        // landscape mode
        // radius = 1/5 of the width
        radius = rect.size.width * 0.2;
    }
    
    CGFloat xFirst, yFirst;
    CGFloat x, y;
    double radian;
    for (int i = 0; i < 360; i+= 36) 
    {
        radian = (1.0 * i + 180)/180 * M_PI;
        
        if (i % 72 == 0)
        {
            x = centerX + sin(radian) * radius;
            y = centerY + cos(radian) * radius;
        }
        else
        {
            x = centerX + sin(radian) * (0.38*radius);
            y = centerY + cos(radian) * (0.38*radius);
        }
        
        if (i == 0)
        {
            CGContextMoveToPoint(context, x, y);
            xFirst = x;
            yFirst = y;
        }
        else
        {
            CGContextAddLineToPoint(context, x, y);
        }
    }
    CGContextAddLineToPoint(context, xFirst, yFirst);
    
    CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
    CGContextFillPath(context);
}

@end
