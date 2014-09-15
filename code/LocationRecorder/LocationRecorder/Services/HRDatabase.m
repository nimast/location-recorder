//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "HRDatabase.h"
#import "FMDatabase.h"
#import "HRFileSystemHelper.h"
#import "FMDatabaseQueue.h"

typedef NSString *string;

@interface HRDatabase ()

@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) FMDatabaseQueue *queue;

@end

@implementation HRDatabase

- (id)init {
	self = [super init];
	if (self) {
		NSString *const databaseName = @"location_recorder.db";
		NSString *databasePath = [HRFileSystemHelper pathInDocumentsDirectory:databaseName];
		self.database = [FMDatabase databaseWithPath:databasePath];


		NSString *createRecordingSessionSQL =
				@"CREATE TABLE IF NOT EXISTS recording_sessions (" \
                            "_id TEXT PRIMARY KEY," \
                            "start_date INTEGER," \
                             "end_date INTEGER," \
                            "name TEXT);";

		NSString *createRecordingSnapshotSQL =
				@"CREATE TABLE IF NOT EXISTS recording_session_snapshots (" \
                            "_id INTEGER PRIMARY KEY AUTOINCREMENT," \
                            "recording_session_id INTEGER," \
                            "time_position REAL," \
                            "location_lat REAL," \
                            "location_long REAL," \
                            "FOREIGN KEY(recording_session_id) REFERENCES recording_sessions(id));";

		[self.database open];
		[self.database executeUpdate:createRecordingSessionSQL];
		[self.database executeUpdate:createRecordingSnapshotSQL];
		[self.database close];

		self.queue = [[FMDatabaseQueue alloc] initWithPath:databasePath];
	}

	return self;
}

- (void)inDatabase:(void (^)(FMDatabase *db))block {
	[self.queue inDatabase:block];
}

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
	[self.queue inTransaction:block];
}


@end