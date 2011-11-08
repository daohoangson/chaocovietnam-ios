//
//  ViewController.h
//  Chao Co Viet Nam
//
//  Created by Son Dao Hoang on 11/8/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVAudioPlayerDelegate>
{
    AVAudioPlayer *audioPlayer;
    NSTimer *timer;
    NSDictionary *lyrics;
}
@property (strong, nonatomic) IBOutlet UIButton *btnStart;
@property (strong, nonatomic) IBOutlet UILabel *lblLyrics;

- (void)positionLyrics;

- (IBAction)btnStartTouchUpInside:(id)sender;

- (void)startPlaying;
- (void)pausePlaying;
- (void)audioPlayerTick;

@end
