//
//  MainViewController.m
//  chaocovietnam
//
//  Created by Son Dao Hoang on 11/17/11.
//  Copyright (c) 2011 UET. All rights reserved.
//

#import "SBJson.h"
#import "MainViewController.h"

@implementation MainViewController

@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize lblLyrics = _lblLyrics;
@synthesize btnAction = _btnAction;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

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
    broadcastSentTime = 0;
    syncBaseTime = 0;
    syncDeviceName = nil;
    syncUpdatedTime = 0;
}

- (void)viewDidUnload
{
    [self setLblLyrics:nil];
    [self setBtnAction:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [_flipsidePopoverController release];
    [_lblLyrics release];
    [_btnAction release];
    
    if (audioPlayer.playing)
    {
        [self pausePlaying];
    }
    [audioPlayer release];
    [lyrics release];
    
    [socket close];
    [socket release];
    [deviceName release];
    
    [super dealloc];
}

#pragma mark - Rotating stuff

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
    
    [_lblLyrics setHidden:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self positionLyrics];
    
    [_lblLyrics setHidden:NO];
}

- (void)positionLyrics
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
    {
        // we are on a small screen (iPhone, iPod Touch) and in portrait mode
        // let's move the lyrics to above the start button so longer text can appear
        CGRect frame = _btnAction.frame;
        frame.origin.y = _btnAction.frame.origin.y - _btnAction.frame.size.height;
        frame.size.width = self.view.bounds.size.width - 2*(_btnAction.frame.origin.x);
        [_lblLyrics setFrame:frame];
    }
    else
    {
        // just put the lyrics next to the button
        CGRect frame = _btnAction.frame;
        frame.origin.x = 2*_btnAction.frame.origin.x + _btnAction.frame.size.width;
        frame.size.width = self.view.bounds.size.width - 3*(_btnAction.frame.origin.x) - _btnAction.frame.size.width;
        [_lblLyrics setFrame:frame];
    }
    
    [_lblLyrics setText:@""];
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

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self pausePlaying];
}

- (void)startPlaying
{
    [audioPlayer play];
    timer = [NSTimer scheduledTimerWithTimeInterval:CHAOCOVIETNAM_TIMER_STEP target:self selector:@selector(audioPlayerTick) userInfo:nil repeats:YES];
    
    [_btnAction setTitle:@"Pause" forState:0];
    [_lblLyrics setText:@""];
    
    broadcastSentTime = 0;
    syncBaseTime = 0;
    syncDeviceName = nil;
    syncUpdatedTime = 0;
}

- (void)pausePlaying
{
    [audioPlayer pause];
    [timer invalidate];
    
    [_btnAction setTitle:@"Play" forState:0];
    [_lblLyrics setText:@""];
}

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
    if (syncBaseTime == 0 || audioPlayer.playing)
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
        return;
    }
    
    // updates the lyrics using the normal flow code
    [self updateLyrics:baseOffset from:syncDeviceName];
    
    // schedule this function again...
    [NSTimer scheduledTimerWithTimeInterval:CHAOCOVIETNAM_TIMER_STEP target:self selector:@selector(syncPlayerTick) userInfo:nil repeats:NO];
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
    
    [_lblLyrics setText:maxLyric];
}

#pragma mark - AsyncUdpSocketDelegate

- (void)socketBroadcast:(float)seconds
{
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [NSString stringWithFormat:@"%.2f", seconds], CHAOCOVIETNAM_DATA_KEY_SECONDS,
                          deviceName, CHAOCOVIETNAM_DATA_KEY_NAME,
                          nil];
    NSString *str = [dict JSONRepresentation];
    NSData *data = [NSData dataWithData:[str dataUsingEncoding:NSASCIIStringEncoding]];
    [socket sendData:data toHost:@"255.255.255.255" port:CHAOCOVIETNAM_PORT withTimeout:-1 tag:0];

    [dict release];
}

- (void)socketParse:(NSData *)data fromHost:(NSString *)host
{
    NSString *str;
    str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];

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
                if (currentTime - syncBaseTime > 1)
                {
                    // checks to deal with double udp message (ipv4 and ipv6)
                    syncBaseTime = currentTime - seconds;
                    syncDeviceName = [name retain];
                    syncUpdatedTime = currentTime;
                    
                    [self syncPlayerTick];
                }
            }
        }
    }
    [str release];
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    [self socketParse:data fromHost:host];
    
    return NO;
}

@end
