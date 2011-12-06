//
//  StarView.h
//  Chao Co Viet Nam
//
//  Created by Son Dao Hoang on 11/8/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StarViewDelegate <NSObject>

- (void)onScrolling:(float)percent;

@end

@interface StarView : UIView {
    float percent;
}

@property (nonatomic, assign) id<StarViewDelegate> starViewDelegate;

- (void)initCommon;
- (void)setPercent:(float)percent;

@end
