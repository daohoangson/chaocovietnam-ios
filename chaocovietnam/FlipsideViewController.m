//
//  FlipsideViewController.m
//  chaocovietnam
//
//  Created by Son Dao Hoang on 11/17/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import "FlipsideViewController.h"

@implementation FlipsideViewController
@synthesize tabBarController = _tabBarController;
@synthesize lblIntro1 = _lblIntro1;
@synthesize lblIntro2 = _lblIntro2;

@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    }
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.lblIntro1 setTextAlignment:UITextAlignmentJustify];
    [self.lblIntro2 setTextAlignment:UITextAlignmentJustify];

    self.tabBarController.view.frame = CGRectMake(0, 50, 320, 410);    
    [self.view addSubview:self.tabBarController.view];
}

- (void)viewDidUnload
{
    [self setLblIntro1:nil];
    [self setTabBarController:nil];
    [self setLblIntro2:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (void)dealloc {
    [_lblIntro1 release];
    [_tabBarController release];
    [_lblIntro2 release];
    [super dealloc];
}
@end
