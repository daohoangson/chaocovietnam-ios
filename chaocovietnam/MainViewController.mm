//
//  MainViewController.m
//  chaocovietnam
//
//  Created by Son Dao Hoang on 11/17/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import "SBJson.h"
#import "MainViewController.h"
#import "Debug.h"

@implementation MainViewController

@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize lblLyrics = _lblLyrics;
@synthesize btnAction = _btnAction;
@synthesize btnSecondaryAction = _btnSecondaryAction;
@synthesize starView = _starView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _starView.starViewDelegate = self;

    // loads the mp3
    if (audioPlayer == nil)
    {
        NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Vietnam_National_Anthem_-_Tien_Quan_Ca" ofType:@"mp3"]];
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        audioPlayer.delegate = self;
        [audioPlayer prepareToPlay];
    }
    
    // loads the lyrics
    if (lyrics == nil)
    {
        lyrics = [[NSDictionary dictionaryWithObjectsAndKeys:
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
                  nil] retain];
    }
    [_lblLyrics setText:@""];
    
    // inits the socket
    if (socket == nil)
    {
        socket = [[AsyncUdpSocket alloc] initWithDelegate:self];
        [socket bindToPort:CHAOCOVIETNAM_PORT error:nil];
        [socket enableBroadcast:YES error:nil];
        [socket receiveWithTimeout:-1 tag:0];
    }
    
    // broadcast / sync stuff
    NSString *deviceNameRaw = [[UIDevice currentDevice] name];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"[^a-z0-9 ]" options:NSRegularExpressionCaseInsensitive error:nil];
    deviceName = [[regex stringByReplacingMatchesInString:deviceNameRaw options:0 range:NSMakeRange(0, [deviceNameRaw length]) withTemplate:@""] retain]; // the device name has to be altered because special characters fcuk the UDP message (in my tests, it the single quote character)
    [regex release];
    broadcastSentTime = 0;
    syncBaseTime = 0;
    syncDeviceName = nil;
    syncUpdatedTime = 0;
    
    // recorder stuff
    recorder = new Recorder();
    recorderBaseTime = 0;
    recorderTick2BaseTime = 0;
}

- (void)viewDidUnload
{
    [self setLblLyrics:nil];
    [self setBtnAction:nil];
    [self setStarView:nil];
    [self setBtnSecondaryAction:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [_flipsidePopoverController release];
    [_lblLyrics release];
    [_btnAction release];
    [_starView release];
    [_btnSecondaryAction release];
    
    if (audioPlayer.playing)
    {
        [self pausePlaying];
    }
    [audioPlayer release];
    [lyrics release];
    
    [socket close];
    [socket release];
    [deviceName release];
    
    delete recorder;
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - Rotating stuff

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
    
    [_lblLyrics setHidden:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [_lblLyrics setHidden:NO];
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    }
}

- (IBAction)showInfo:(id)sender
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        FlipsideViewController *controller = [[[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil] autorelease];
        controller.delegate = self;
        controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:controller animated:YES];
    } else {
        if (!self.flipsidePopoverController) {
            FlipsideViewController *controller = [[[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil] autorelease];
            controller.delegate = self;
            
            self.flipsidePopoverController = [[[UIPopoverController alloc] initWithContentViewController:controller] autorelease];
        }
        if ([self.flipsidePopoverController isPopoverVisible]) {
            [self.flipsidePopoverController dismissPopoverAnimated:YES];
        } else {
            [self.flipsidePopoverController presentPopoverFromRect:((UIButton *)sender).bounds inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

#pragma mark - Actions

- (IBAction)doAction:(id)sender
{
    // give the double tap 0.2 second to happen
    [self performSelector:@selector(resumeOrPause) withObject:sender afterDelay:0.2];
}

- (IBAction)doActionDeeper:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resumeOrPause) object:sender];
    [self startOrStop];
}

- (IBAction)doSecondaryAction:(id)sender {
    if (audioPlayer.playing)
    {
        // do nothing
    }
    else
    {
        if (recorder->isRunning())
        {
            // also do nothing
            // it should be disabled actually
            // recorder->stopRecording();
        }
        else
        {
            // fix a silly bug
            // remove this line and recorder will fail to AudioQueueStart
            // probably because audioPlayer is still holding the AudioSession...
            [audioPlayer stop];
            
            recorder->startRecording();
            [self recorderTick];
        }
        
        [_btnSecondaryAction setEnabled:NO];
    }
}

- (void)resumeOrPause
{
    if (audioPlayer.playing)
    {
        // it's playing, pause now
        [self pausePlaying];
    }
    else
    {
        // it's not playing, resume now
        [self startPlaying];
    }
}

- (void)startOrStop
{
    if (audioPlayer.playing)
    {
        // it's playing, this means a full stop (instead of pause)
        [self pausePlaying];
        [audioPlayer setCurrentTime:0];
    }
    else
    {
        // it's not playing, this means start from the beginning (instead of resume)
        [audioPlayer setCurrentTime:0];
        [self startPlaying];
    }
}

- (void)startPlaying
{
    [audioPlayer play];
    timer = [NSTimer scheduledTimerWithTimeInterval:CHAOCOVIETNAM_TIMER_STEP target:self selector:@selector(audioPlayerTick) userInfo:nil repeats:YES];
    
    [_btnAction setTitle:NSLocalizedString(@"BUTTON_STOP", nil) forState:0];
    [_lblLyrics setText:@""];
    [_btnSecondaryAction setEnabled:NO];
    
    broadcastSentTime = 0;
    syncBaseTime = 0;
    syncDeviceName = nil;
    syncUpdatedTime = 0;
    
    recorderBaseTime = 0;
}

- (void)pausePlaying
{
    [audioPlayer pause];
    if (timer != nil) 
    {
        [timer invalidate];
        timer = nil;
    }
    
    [_btnAction setTitle:NSLocalizedString(@"BUTTON_PLAY", nil) forState:0];
    [_lblLyrics setText:@""];
    [_btnSecondaryAction setEnabled:YES];
}

- (void)updateLyrics:(float)seconds from:(NSString *)fromDeviceName;
{
    float maxTime = 0;
    float time = 0;
    NSString *maxLyric = @"";
    
    for (NSNumber *key in lyrics)
    {
        time = [key floatValue];
        if (seconds > time && maxTime < time)
        {
            maxTime = time;
            maxLyric = [lyrics objectForKey:key];
        }
    }
    
    if ([maxLyric length] > 0 && fromDeviceName != nil)
    {
        // this is from another device (sync mode)
        // appends the device name
        maxLyric = [NSString stringWithFormat:@"%@ (%@)", maxLyric, fromDeviceName];
    }
    
    [self.starView setPercent:seconds/audioPlayer.duration];
    [_lblLyrics setText:maxLyric];
    
    DLog(@"updateLyrics: %g, %@, %@", seconds, fromDeviceName, maxLyric);
}

#pragma mark - Timer stuff

- (void)audioPlayerTick
{
    float seconds = audioPlayer.currentTime + CHAOCOVIETNAM_TIMER_STEP; // it's better to go ahead
    
    [self updateLyrics:seconds from:nil];
    
    float currentTime = CACurrentMediaTime();
    if (currentTime - broadcastSentTime > CHAOCOVIETNAM_SYNC_BROADCAST_STEP)
    {
        // it's time to broadcast
        [self socketBroadcast:seconds];
        // marks as sent
        broadcastSentTime = currentTime;
    }
}

- (void)syncPlayerTick
{
    if (syncBaseTime == 0 || audioPlayer.playing || recorderBaseTime > 0)
    {
        // nothing to do here
        return;
    }
    
    float currentTime = CACurrentMediaTime();
    float baseOffset = currentTime - syncBaseTime;
    float updatedOffset = currentTime - syncUpdatedTime;
    
    if (updatedOffset > CHAOCOVIETNAM_SYNC_MAX_DURATION)
    {
        // no signal from the host for too long
        // reset control state and stop looping
        [self pausePlaying];
        syncBaseTime = 0;
        syncUpdatedTime = 0;
        return;
    }
    
    // updates the lyrics using the normal flow code
    [self updateLyrics:baseOffset from:syncDeviceName];
    
    // schedule this function again...
    [NSTimer scheduledTimerWithTimeInterval:CHAOCOVIETNAM_TIMER_STEP target:self selector:@selector(syncPlayerTick) userInfo:nil repeats:NO];
}

- (void)recorderTick
{
    if (recorder->isRunning())
    {
        // it's still recording
        // nothing to do here
        [NSTimer scheduledTimerWithTimeInterval:CHAOCOVIETNAM_TIMER_STEP target:self selector:@selector(recorderTick) userInfo:nil repeats:NO];
        
        DLog(@"Waiting for recorder...");
    }
    else
    {
        recorderBaseTime = recorder->getRecognizedBaseTime();
        [_btnSecondaryAction setEnabled:YES];
        
        [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(recorderTick2) userInfo:nil repeats:NO];
    }
}

- (void)recorderTick2
{
    if (recorderBaseTime == 0 || audioPlayer.playing)
    {
        // nothing to do here
        return;
    }
    
    if (recorderTick2BaseTime != 0 && recorderTick2BaseTime != recorderBaseTime)
    {
        // there is another recorderTick2 has been trigger
        // we should stop here
        [self pausePlaying];
        recorderTick2BaseTime = 0;
        return;
    }
    
    recorderTick2BaseTime = recorderBaseTime;
    float currentTime = CACurrentMediaTime();
    float baseOffset = currentTime - recorderBaseTime;
    
    if (baseOffset > audioPlayer.duration)
    {
        // well, we have to stop sometime...
        [self pausePlaying];
        recorderTick2BaseTime = 0;
        recorderBaseTime = 0;
        return;
    }
    
    // updates the lyrics using the normal flow code
    [self updateLyrics:baseOffset from:@"Air"];
    
    // schedule this function again...
    [NSTimer scheduledTimerWithTimeInterval:CHAOCOVIETNAM_TIMER_STEP target:self selector:@selector(recorderTick2) userInfo:nil repeats:NO];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self pausePlaying];
}

#pragma mark - AsyncUdpSocketDelegate

- (void)socketBroadcast:(float)seconds
{
    NSString *strSeconds = [NSString stringWithFormat:@"%.2f", seconds];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                          strSeconds, CHAOCOVIETNAM_DATA_KEY_SECONDS,
                          deviceName, CHAOCOVIETNAM_DATA_KEY_NAME,
                          nil];
    NSString *str = [dict JSONRepresentation];
    NSString *host = @"255.255.255.255";
    NSData *data = [NSData dataWithData:[str dataUsingEncoding:NSASCIIStringEncoding]];
    [socket sendData:data toHost:host port:CHAOCOVIETNAM_PORT withTimeout:-1 tag:0];
    
    DLog(@"Sent %@ to %@", str, host);

    [dict release];
}

- (void)socketParse:(NSData *)data fromHost:(NSString *)host
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSDictionary *dict = [str JSONValue];
    
    if (dict != nil)
    {
        float seconds = [[dict objectForKey:CHAOCOVIETNAM_DATA_KEY_SECONDS] floatValue];
        NSString *name = [dict objectForKey:CHAOCOVIETNAM_DATA_KEY_NAME];
        
        if (seconds > 0)
        {
            // caught a command
            if (audioPlayer.playing == false) 
            {
                // only works if the player is not playing
                // this check will keeps us from working with our own broadcast message
                // that's silly!
                float currentTime = CACurrentMediaTime();
                if (currentTime - syncUpdatedTime > 1)
                {
                    // checks to deal with double udp message (ipv4 and ipv6)
                    syncBaseTime = currentTime - seconds;
                    syncDeviceName = [name retain];
                    syncUpdatedTime = currentTime;
                    
                    [self syncPlayerTick];
                }
            }
        }
        
        [dict release];
    }
    
    DLog(@"Received %@ from %@", str, host);
    
    [str release];
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    [self socketParse:data fromHost:host];
    
    return NO;
}

#pragma mark - StarViewDelegate

- (void)onScrolling:(float)percent
{
    if (audioPlayer.playing)
    {
        // in play back mode
        // simply adjust the currentTime of the player
        audioPlayer.currentTime = audioPlayer.duration * percent;
        [_starView setPercent:percent];
    }
    else if (recorderBaseTime > 0)
    {
        // in recorder sync mode
        // adjust the base time to achieve the desired effect
        float currentTime = CACurrentMediaTime() - recorderBaseTime;
        float newCurrentTime = audioPlayer.duration * percent;
        float newBaseTime = recorderBaseTime - (newCurrentTime - currentTime);
        recorderBaseTime = newBaseTime;
        recorderTick2BaseTime = newBaseTime; // we have to update this too or it will stop itself
        [_starView setPercent:percent];
    }
}

@end
