//
//  StarView.m
//  Chao Co Viet Nam
//
//  Created by Son Dao Hoang on 11/8/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import "StarView.h"

@implementation StarView

@synthesize starViewDelegate=_starViewDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (void)initCommon
{
    percent = 0.f;
    self.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)setPercent:(float)newPercent
{
    if (newPercent > 0 && newPercent <= 1.f)
    {
        percent = newPercent;
    }
    else
    {
        percent = 0.f;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint loc = [touch locationInView:self];
        CGPoint prevLoc = [touch previousLocationInView:self];
        float dx = (loc.x - prevLoc.x) / self.frame.size.width * 2;
        float dy = (prevLoc.y - loc.y) / self.frame.size.height * 2;
        float dxAbs = fabsf(dx);
        float dyAbs = fabsf(dy);
        
        if (dxAbs > 0.02 || dyAbs > 0.02)
        {
            // only continue if the move is significant (reduce noise)
            float d = dxAbs > dyAbs ? dx : dy;
            float newPercent = percent + d;
            
            if (newPercent >= 0 && newPercent <= 1)
            {
                // only continue if the new percent is valid (within range 0..1)
                [_starViewDelegate onScrolling:newPercent];
            }
        }
    }
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
    
    // draw the percentage
    if (percent > 0)
    {
        CGFloat rectHeight = percent * rect.size.height;
        CGRect rectangle = CGRectMake(0, rect.size.height - rectHeight, 2, rectHeight);
        
        /*
        CGContextSetLineWidth(context, 2.0);
        CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
        CGContextAddRect(context, rectangle);
        CGContextStrokePath(context);
        */
        CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
        CGContextFillRect(context, rectangle);
    }
}

@end
