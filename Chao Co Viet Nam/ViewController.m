//
//  ViewController.m
//  Chao Co Viet Nam
//
//  Created by Son Dao Hoang on 11/8/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize btnStart;
@synthesize lblLyrics;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Vietnam_National_Anthem_-_Tien_Quan_Ca" ofType:@"mp3"]];
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error)
    {
        // hmm
    }
    else
    {
        audioPlayer.delegate = self;
        [audioPlayer prepareToPlay];
    }
    
    lyrics = [NSDictionary dictionaryWithObjectsAndKeys:
              // part 1
              @"Đoàn quân Việt Nam đi", [NSNumber numberWithFloat:8.0],
              @"Chung lòng cứu quốc", [NSNumber numberWithFloat:11.5],
              @"Bước chân dồn vang trên đường gập ghềnh xa", [NSNumber numberWithFloat:14.5],
              @"Cờ in máu chiến thắng mang hồn nước,", [NSNumber numberWithFloat:20.0],
              @"Súng ngoài xa chen khúc quân hành ca.", [NSNumber numberWithFloat:26.0],
              @"Đường vinh quang xây xác quân thù,", [NSNumber numberWithFloat:32.0],
              @"Thắng gian lao cùng nhau lập chiến khu.", [NSNumber numberWithFloat:37.0],
              @"Vì nhân dân chiến đấu không ngừng,", [NSNumber numberWithFloat:43.5],
              @"Tiến mau ra sa trường,", [NSNumber numberWithFloat:48.5],
              @"Tiến lên, cùng tiến lên.", [NSNumber numberWithFloat:52.5],
              @"Nước non Việt Nam ta vững bền.", [NSNumber numberWithFloat:60.0],
              // part 2
              @"Đoàn quân Việt Nam đi", [NSNumber numberWithFloat:67.0],
              @"Sao vàng phấp phới", [NSNumber numberWithFloat:70.0],
              @"Dắt giống nòi quê hương qua nơi lầm than", [NSNumber numberWithFloat:72.5],
              @"Cùng chung sức phấn đấu xây đời mới,", [NSNumber numberWithFloat:77.5],
              @"Đứng đều lên gông xích ta đập tan.", [NSNumber numberWithFloat:84.0],
              @"Từ bao lâu ta nuốt căm hờn,", [NSNumber numberWithFloat:89.0],
              @"Quyết hy sinh đời ta tươi thắm hơn.", [NSNumber numberWithFloat:94.0],
              @"Vì nhân dân chiến đấu không ngừng,", [NSNumber numberWithFloat:100.5],
              @"Tiến mau ra sa trường,", [NSNumber numberWithFloat:106.5],
              @"Tiến lên, cùng tiến lên.", [NSNumber numberWithFloat:109.5],
              @"Nước non Việt Nam ta vững bền.", [NSNumber numberWithFloat:117.5],
              @"", [NSNumber numberWithFloat:127.5],
              nil];
}

- (void)viewDidUnload
{
    [self setBtnStart:nil];
    [self setLblLyrics:nil];
    [super viewDidUnload];
    
    audioPlayer = nil;
    lyrics = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self positionLyrics];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [lblLyrics setHidden:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self positionLyrics];
    
    [lblLyrics setHidden:NO];
}

- (void)positionLyrics
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
    {
        // we are on a small screen (iPhone, iPod Touch) and in portrait mode
        // let's move the lyrics to above the start button so longer text can appear
        CGRect frame = btnStart.frame;
        frame.origin.y = btnStart.frame.origin.y - btnStart.frame.size.height;
        frame.size.width = self.view.bounds.size.width - 2*(btnStart.frame.origin.x);
        [lblLyrics setFrame:frame];
    }
    else
    {
        // just put the lyrics next to the button
        CGRect frame = btnStart.frame;
        frame.origin.x = 2*btnStart.frame.origin.x + btnStart.frame.size.width;
        frame.size.width = self.view.bounds.size.width - 3*(btnStart.frame.origin.x) - btnStart.frame.size.width;
        [lblLyrics setFrame:frame];
    }
    
    [lblLyrics setText:@""];
}

#pragma mark - AVAudioPlayerDelegate stuff

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [timer invalidate];
}

- (void)startPlaying
{
    [audioPlayer play];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(audioPlayerTick) userInfo:nil repeats:YES];
    
    [btnStart setTitle:@"Pause" forState:0];
    [lblLyrics setText:@""];
}

- (void)pausePlaying
{
    [audioPlayer pause];
    [timer invalidate];
    
    [btnStart setTitle:@"Play" forState:0];
    [lblLyrics setText:@""];
}

- (void)audioPlayerTick
{
    float currentTime = audioPlayer.currentTime + 0.5; // it's better to go ahead
    float maxTime = 0;
    float time = 0;
    NSString *maxLyric = @"";
    
    for (NSNumber *key in lyrics)
    {
        time = [key floatValue];
        if (currentTime > time && maxTime < time)
        {
            maxTime = time;
            maxLyric = [lyrics objectForKey:key];
        }
    }
    
    [lblLyrics setText:maxLyric];
}

#pragma mark -

- (IBAction)btnStartTouchUpInside:(id)sender {
    if (audioPlayer.playing)
    {
        [self pausePlaying];
    }
    else
    {
        [self startPlaying];
    }
}
@end
