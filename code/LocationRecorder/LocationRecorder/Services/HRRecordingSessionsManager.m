//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "AEAudioFilePlayer.h"
#import "HRRecordViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MacTypes.h>
#import "HRRecordingSessionsManager.h"
#import "HRDatabase.h"
#import "HRRecordingSession.h"
#import "HRRecordingSession.h"
#import "FMDatabase.h"
#import "HRecordingSessionSnapshot.h"

@interface HRRecordingSessionsManager ()

#pragma Services

@property (nonatomic, strong) HRDatabase *database;

@end

@implementation HRRecordingSessionsManager

- (id)init {
	self = [super init];
	if (self) {
		self.database = [[HRDatabase alloc] init];
	}

	return self;
}

+ (HRRecordingSessionsManager *)instance {
	static HRRecordingSessionsManager *_instance = nil;

	@synchronized (self) {
		if (_instance == nil) {
			_instance = [[self alloc] init];
		}
	}

	return _instance;
}

- (HRRecordingSession *)createAndStartRecordingSession {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd_hhmmss"];

	NSString *dateString = [formatter stringFromDate:[NSDate date]];
	NSDate *startDate = [NSDate date];
	NSString *sessionName = [@"session_" stringByAppendingString:dateString];

	HRRecordingSession *session = [[HRRecordingSession alloc] initWithName:sessionName];
	session.objectId = [[NSUUID UUID] UUIDString];
	session.startDate = startDate;
	session.name = sessionName;
	NSString *createSQL = @"INSERT INTO recording_sessions (_id, start_date, name) VALUES (?, ?, ?)";
	NSArray *parameters =
			@[session.objectId,
					session.startDate,
					session.name];

	__block BOOL result;

	[self.database inTransaction:^(FMDatabase *db, BOOL *rollback) {
		result = [db executeUpdate:createSQL withArgumentsInArray:parameters];
	}];

	if (!result) {
		NSLog(@"Could not create recording session");
	}

	return session;
}

- (BOOL)stopRecordingSession:(HRRecordingSession *)session {
	NSDate *sessionEnd = [NSDate date];
	NSString *updateSQL = [NSString stringWithFormat:@"UPDATE recording_sessions SET end_date = :end_date WHERE _id = '%@'", session.objectId];
	NSDictionary *updateParameters = @{
			@"end_date" : sessionEnd
	};

	__block BOOL updateResult;
	[self.database inTransaction:^(FMDatabase *db, BOOL *rollback) {
		updateResult = [db executeUpdate:updateSQL withParameterDictionary:updateParameters];
	}];

	return updateResult;
}

- (void)addSnapshot:(HRRecordingSessionSnapshot *)snapshot toRecordingSession:(HRRecordingSession *)session {
	NSString *insertSQL = @"INSERT INTO recording_session_snapshots (time_position, location_lat, location_long, recording_session_id) VALUES (?, ?, ?, ?)";

	NSArray *parameters =
			@[@(snapshot.timestamp),
					@(snapshot.location.coordinate.latitude),
					@(snapshot.location.coordinate.longitude),
					session.objectId];

	__block BOOL insertSuccess;
	[self.database inDatabase:^(FMDatabase *db) {
		insertSuccess = [db executeUpdate:insertSQL withArgumentsInArray:parameters];
	}];

	if (!insertSuccess) {
		NSLog(@"Error associating snapshot with recording session %@ ", session.objectId);
	}
}

- (NSString *)pathForSession:(HRRecordingSession *)session {
	NSString *fileName = [NSString stringWithFormat:@"%@.wav", session.name];

	NSString *documentsFolder = (NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES))[0];
	NSString *filePath = [documentsFolder stringByAppendingPathComponent:fileName];

	return filePath;
}

- (NSArray *)allRecordingSessions {
	NSString *selectSQL = @"SELECT * FROM recording_sessions";

	__block FMResultSet *results;
	[self.database inDatabase:^(FMDatabase *db) {
		results = [db executeQuery:selectSQL];
	}];

	NSMutableArray *sessions = [NSMutableArray array];
	while ([results next]) {
		HRRecordingSession *session = [[HRRecordingSession alloc] init];
		session.objectId = [results stringForColumn:@"_id"];
		session.name = [results stringForColumn:@"name"];
		session.startDate = [results dateForColumn:@"start_date"];
		session.endDate = [results dateForColumn:@"end_date"];

		[sessions addObject:session];
	}

	[results close];

	return sessions;
}

- (NSArray *)snapshotsOfSession:(HRRecordingSession *)session {
	NSString *selectSQL = [NSString stringWithFormat:@"SELECT * FROM recording_session_snapshots WHERE recording_session_id = '%@'", session.objectId];

	__block FMResultSet *results;
	[self.database inDatabase:^(FMDatabase *db) {
		results = [db executeQuery:selectSQL];
	}];

	NSMutableArray *snapshots = [NSMutableArray array];
	while ([results next]) {
		HRRecordingSessionSnapshot *snapshot = [[HRRecordingSessionSnapshot alloc] init];
		double locationLat = [results doubleForColumn:@"location_lat"];
		double locationLong = [results doubleForColumn:@"location_long"];
		CLLocation *location = [[CLLocation alloc] initWithLatitude:locationLat longitude:locationLong];
		snapshot.location = location;
		snapshot.timestamp = [results doubleForColumn:@"time_position"];

		[snapshots addObject:snapshot];
	}

	[results close];

	return snapshots;
}

@end