//
//  FlipsideViewController.h
//  chaocovietnam
//
//  Created by Son Dao Hoang on 11/17/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OHAttributedLabel.h"

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <FlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;
@property (retain, nonatomic) IBOutlet UITabBarController *tabBarController;
@property (retain, nonatomic) IBOutlet OHAttributedLabel *lblIntro1;
@property (retain, nonatomic) IBOutlet OHAttributedLabel *lblIntro2;

@end
