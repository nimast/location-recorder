//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;
@class FMDatabase;

@interface HRDatabase : NSObject

/** Synchronously perform database operations on queue.

@param block The code to be run on the queue of `FMDatabaseQueue`
*/

- (void)inDatabase:(void (^)(FMDatabase *db))block;

/** Synchronously perform database operations on queue, using transactions.

@param block The code to be run on the queue of `FMDatabaseQueue`
*/

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

@end