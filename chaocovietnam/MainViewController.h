//
//  MainViewController.h
//  chaocovietnam
//
//  Created by Son Dao Hoang on 11/17/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FlipsideViewController.h"
#import "AsyncUdpSocket.h"

#define CHAOCOVIETNAM_PORT 25296
#define CHAOCOVIETNAM_TIMER_STEP 0.5
#define CHAOCOVIETNAM_SYNC_BROADCAST_STEP 2
#define CHAOCOVIETNAM_SYNC_MAX_DURATION 5
#define CHAOCOVIETNAM_DATA_KEY_SECONDS @"s"
#define CHAOCOVIETNAM_DATA_KEY_NAME @"n"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, AVAudioPlayerDelegate, AsyncUdpSocketDelegate>
{
    AVAudioPlayer  *audioPlayer;
    NSDictionary   *lyrics;
    
    NSTimer        *timer;
    float          broadcastSentTime;
    
    AsyncUdpSocket *socket;
    NSString       *deviceName;
    float          syncBaseTime;
    NSString       *syncDeviceName;
    float          syncUpdatedTime;
}

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (retain, nonatomic) IBOutlet UILabel *lblLyrics;
@property (retain, nonatomic) IBOutlet UIButton *btnAction;

- (IBAction)showInfo:(id)sender;
- (IBAction)doAction:(id)sender;
- (IBAction)doActionDeeper:(id)sender;
- (void)resumeOrPause;
- (void)startOrStop;

- (void)positionLyrics;
- (void)startPlaying;
- (void)pausePlaying;
- (void)audioPlayerTick;
- (void)syncPlayerTick;
- (void)updateLyrics:(float)seconds from:(NSString *)fromDeviceName;

- (void)socketBroadcast:(float)seconds;
- (void)socketParse:(NSData *)data fromHost:(NSString *)host;

@end
