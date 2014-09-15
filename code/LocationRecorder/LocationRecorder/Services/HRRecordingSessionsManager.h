//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

@class HRRecordingSession;
@class HRRecordingSessionSnapshot;

@interface HRRecordingSessionsManager : NSObject

+ (HRRecordingSessionsManager *)instance;

@property (nonatomic, strong) HRRecordingSession *currentSession;
@property (nonatomic, strong) AEAudioFilePlayer *player;

- (HRRecordingSession *)createAndStartRecordingSession;

- (BOOL)stopRecordingSession:(HRRecordingSession *)session;

- (void)addSnapshot:(HRRecordingSessionSnapshot *)snapshot toRecordingSession:(HRRecordingSession *)session;

- (NSString *)pathForSession:(HRRecordingSession *)session;

- (NSArray *)allRecordingSessions;

- (NSArray *)snapshotsOfSession:(HRRecordingSession *)session;

@end