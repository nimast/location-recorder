//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import "HRRecordViewController.h"
#import "UIControl+RACSignalSupport.h"
#import "EXTScope.h"
#import "RACSignal.h"
#import "AEAudioController.h"
#import "AEAudioFilePlayer.h"
#import "AERecorder.h"
#import "HRFileSystemHelper.h"
#import "ViewUtils.h"
#import "HRLocationManager.h"
#import "HRRecordingSessionsManager.h"
#import "HRecordingSessionSnapshot.h"
#import "HRRecordingSession.h"

@interface HRRecordViewController ()

#pragma Data

@property (nonatomic, assign) BOOL recording;
@property (nonatomic, strong) NSDate *recordingStarted;
@property (nonatomic, strong) HRRecordingSession *currentSession;
@property (nonatomic, strong) HRRecordingSession *lastSession;
@property (nonatomic, strong) dispatch_source_t timer;

#pragma Views

@property (nonatomic, weak) UIButton *recordStopButton;
@property (nonatomic, weak) UIButton *playButton;
@property (nonatomic, weak) UILabel *recordingTimestamp;
@property (nonatomic, weak) UILabel *timeSinceRecording;

#pragma Services

@property (nonatomic, strong) AEAudioController *audioController;
@property (nonatomic, strong) AERecorder *recorder;
@property (nonatomic, strong) AEBlockFilter *locationRecordingFilter;
@property (nonatomic, strong) HRLocationManager *locationManager;
@property (nonatomic, strong) HRRecordingSessionsManager *sessionsManager;

@end

@implementation HRRecordViewController

- (NSString *)title {
	return @"Record";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		self.audioController = [[AEAudioController alloc]
				initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
							inputEnabled:YES];

		self.locationManager = [[HRLocationManager alloc] init];
		self.sessionsManager = [HRRecordingSessionsManager instance];

		dispatch_source_t timer = dispatch_source_create(
				DISPATCH_SOURCE_TYPE_TIMER,
				0,
				0,
				dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

		if (timer) {
			dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 1ull * NSEC_PER_SEC, 0);
			dispatch_source_set_event_handler(timer, ^{
				if (!_recording || self.currentSession == nil) {
					return;
				}

				double currentTime = self.recorder.currentTime;
				CLLocation *currentLocation = [self.locationManager.currentLocation copy];
				HRRecordingSessionSnapshot *snapshot = [[HRRecordingSessionSnapshot alloc] init];
				snapshot.timestamp = currentTime;
				snapshot.location = currentLocation;
				[self.sessionsManager addSnapshot:snapshot toRecordingSession:self.currentSession];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self displayTimespan:currentTime onLabel:self.recordingTimestamp withTitle:@"timestamp: "];
					[self displayTimespan:[self.recordingStarted timeIntervalSinceNow] onLabel:self.timeSinceRecording withTitle:@"time passed·: "];
				});
			});
			dispatch_resume(timer);
		}

		self.timer = timer;

//		self.locationRecordingFilter = [AEBlockFilter filterWithBlock:^(
//				AEAudioControllerFilterProducer producer,
//				void *producerToken,
//				const AudioTimeStamp const *time,
//				UInt32 frames,
//				AudioBufferList *audio) {
//			OSStatus status = producer(producerToken, audio, &frames);
//			if (status != noErr) return;
//
//			double timestamp = time->mSampleTime / self.audioController.
//		}];

		AERecorder *recorder = [[AERecorder alloc] initWithAudioController:self.audioController];
		self.recorder = recorder;
		[self.audioController addInputReceiver:recorder];
		[self.audioController addOutputReceiver:recorder];

		// Playthrough

	}

	return self;
}

- (void)displayTimespan:(NSTimeInterval)interval onLabel:(UILabel *)label withTitle:(NSString *)title {
	NSInteger ti = (NSInteger) interval;
	NSInteger seconds = ti % 60;
	NSInteger minutes = (ti / 60) % 60;
	NSInteger hours = (ti / 3600);
	label.text = [NSString stringWithFormat:@"%@: %02ld:%02ld:%02ld", title, (long) hours, (long) minutes, (long) seconds];
	[label sizeToFit];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	__block NSError *error;
	[self.audioController start:&error];
	if (error) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Recording error" message:@"Could not initialize audio engine" delegate:nil cancelButtonTitle:@"Shit" otherButtonTitles:nil];
		[alertView show];
	}

	UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	self.recordStopButton = recordButton;
	recordButton.titleLabel.text = @"Record";
	[recordButton setTitle:@"Record" forState:UIControlStateNormal];
	recordButton.titleLabel.textColor = [UIColor cyanColor];
	recordButton.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.1];
	@weakify(self);
	[[recordButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
		@strongify(self);
		if (self.recording) {
			self.recording = NO;
			[self.sessionsManager stopRecordingSession:self.currentSession];
			self.lastSession = self.currentSession;
			self.currentSession = nil;
			[recordButton setTitle:@"Record" forState:UIControlStateNormal];
			self.recordingStarted = nil;
			[self.recorder finishRecording];
		} else {
			self.recording = YES;
			self.recordingStarted = [NSDate date];
			self.currentSession = [self.sessionsManager createAndStartRecordingSession];
			NSString *sessionFilePath = [self.sessionsManager pathForSession:self.currentSession];
			[HRFileSystemHelper ensurePathExists:sessionFilePath];

			if (![self.recorder beginRecordingToFileAtPath:sessionFilePath fileType:kAudioFileWAVEType error:&error]) {
				// error;
				return;
			}


			[self.recordStopButton setTitle:@"Stop" forState:UIControlStateNormal];
		}

	}];

	[recordButton sizeToFit];
	CGFloat left = floorf((self.view.width - recordButton.width) / 2);
	recordButton.left = left;
	recordButton.top = 200;
	[self.view addSubview:recordButton];

	UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	self.playButton = playButton;
	[self.playButton setTitle:@"Play" forState:UIControlStateNormal];
	[self.playButton sizeToFit];
	self.playButton.left = floorf((self.view.width - playButton.width) / 2);
	self.playButton.top = 300;
	[self.view addSubview:self.playButton];

	[[self.playButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
		NSError *error;

		HRRecordingSession *sessionToPlay = self.sessionsManager.currentSession;
		if (!sessionToPlay) {
			sessionToPlay = self.lastSession;
		}

		if (!sessionToPlay) {
			return;
		}

		NSString *lastSessionFilePath = [self.sessionsManager pathForSession:sessionToPlay];

		NSURL *fileURL = [[NSURL alloc] initWithString:lastSessionFilePath];

		AEAudioFilePlayer *player = [AEAudioFilePlayer audioFilePlayerWithURL:fileURL
															  audioController:self.audioController
																		error:&error];


		player.completionBlock = ^{
			NSLog(@"Completed!");
		};

		if (self.sessionsManager.player) {
			[self.audioController removeChannels:@[self.sessionsManager.player]];
		}

		self.sessionsManager.player = player;
		[self.audioController addChannels:@[player]];
	}];

	UILabel *recordingTimestampLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	recordingTimestampLabel.left = 20;
	recordingTimestampLabel.top = 350;
	recordingTimestampLabel.text = @"timestamp";
	[recordingTimestampLabel sizeToFit];
	recordingTimestampLabel.textColor = [UIColor cyanColor];
	[self.view addSubview:recordingTimestampLabel];
	self.recordingTimestamp = recordingTimestampLabel;

	UILabel *timeSincerecording = [[UILabel alloc] initWithFrame:CGRectZero];
	timeSincerecording.left = 20;
	timeSincerecording.top = 400;
	timeSincerecording.text = @"time since";
	[timeSincerecording sizeToFit];
	timeSincerecording.textColor = [UIColor cyanColor];
	[self.view addSubview:timeSincerecording];
	self.timeSinceRecording = timeSincerecording;
}

@end