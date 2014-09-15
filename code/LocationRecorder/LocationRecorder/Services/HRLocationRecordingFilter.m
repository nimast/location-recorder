//
// Created by Nimrod Astrahan on 8/9/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "HRLocationRecordingFilter.h"
#import "HRLocationManager.h"

@interface HRLocationRecordingFilter()

@property (nonatomic, strong) HRLocationManager *locationManager;

@end

@implementation HRLocationRecordingFilter



static OSStatus filterCallback(
		__unsafe_unretained HRLocationRecordingFilter *THIS,
		__unsafe_unretained AEAudioController *audioController,
		AEAudioControllerFilterProducer producer,
		void *producerToken,
		const AudioTimeStamp *time,
		UInt32 frames,
		AudioBufferList *audio) {
	// Pull audio
	OSStatus status = producer(producerToken, audio, &frames);
	if (status != noErr) status;



	return noErr;
}

- (id)init {
	self = [super init];
	if (self) {
		self.locationManager = [[HRLocationManager alloc] init];
	}

	return self;
}


- (AEAudioControllerFilterCallback)filterCallback {
	return filterCallback;
}

@end