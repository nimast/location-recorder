//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HRRecordingSession;

@interface HRFileSystemHelper : NSObject

+ (NSString *)pathForRecordingSession:(HRRecordingSession *)recordingSession;



//TODO: remove
+ (NSString *)tempPath;

+ (NSString *)pathInCachesDirectory:(NSString *)relativePath;

+ (NSString *)pathInDocumentsDirectory:(NSString *)relativePath;

+ (NSString *)pathInLocationRecorderDirectory:(NSString *)relativePath;

// Ensures all directories in the specified file path exist.
+ (NSError *)ensurePathExists:(NSString *)pathToFile;

/*
	If generateRandomName is set to YES, the last six chars of fileNameOrTemplate must be "XXXXXX"
	which will be replaced by a unique filename https://www.kernel.org/doc/man-pages/online/pages/man3/mkstemp.3.html
 */
+ (NSString *)pathInTempDirectory:(NSString *)fileNameOrTemplate withRandomName:(BOOL)generateRandomName;

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePath;

@end