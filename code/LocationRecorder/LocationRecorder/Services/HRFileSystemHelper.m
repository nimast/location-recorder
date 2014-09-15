//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "HRFileSystemHelper.h"
#import "HRRecordingSession.h"

static NSString *const HRFileSystemDirectoryNameLocationRecorder = @"LocationRecorder";

@implementation HRFileSystemHelper

+ (NSString *)locationRecorderDirectoryPath {
	static NSString *locationRecorderFolderPath;

	static dispatch_once_t locationRecorderFolderCreationToken;
	dispatch_once(&locationRecorderFolderCreationToken, ^{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
		locationRecorderFolderPath = [basePath stringByAppendingPathComponent:HRFileSystemDirectoryNameLocationRecorder];
		NSError *error;
		[[NSFileManager defaultManager]
				createDirectoryAtPath:locationRecorderFolderPath
		  withIntermediateDirectories:YES
						   attributes:@{
								   NSURLIsExcludedFromBackupKey : @(YES)
						   }
								error:&error];
	});

	return locationRecorderFolderPath;
}

+ (NSString *)pathForRecordingSession:(HRRecordingSession *)recordingSession {
	return nil;
}

+ (NSString *)tempPath {
	return nil;
}

+ (NSString *)pathInCachesDirectory:(NSString *)relativePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	return [NSString stringWithFormat:@"%@/%@", basePath, relativePath];
}

+ (NSString *)pathInDocumentsDirectory:(NSString *)relativePath {
	NSString *documentsFolder = (NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES))[0];
	NSString *filePath = [documentsFolder stringByAppendingPathComponent:relativePath];
	return filePath;
}

+ (NSString *)pathInLocationRecorderDirectory:(NSString *)relativePath {
	return [[HRFileSystemHelper locationRecorderDirectoryPath] stringByAppendingPathComponent:relativePath];
}

+ (NSError *)ensurePathExists:(NSString *)pathToFile {
	NSArray *pathParts = [pathToFile componentsSeparatedByString:@"/"];
	__block NSString *currentPath = @"";
	__block NSError *error = nil;
	[pathParts
			enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				// Don't proceed when its the file itself.
				if (idx == pathParts.count - 2) {
					*stop = YES;
					return;
				}

				currentPath = [currentPath stringByAppendingFormat:@"/%@", obj];
				// This will not create a folder if it does not exist and will
				// also not result in an error if it does.
				[[NSFileManager defaultManager] createDirectoryAtPath:currentPath
										  withIntermediateDirectories:YES attributes:nil error:&error];

				if (error) {
					*stop = YES;
					return;
				}
			}];

	return error;
}

// The last six chars of fileNameTemplate must be "XXXXXX" which will be replaced by a unique
// filename https://www.kernel.org/doc/man-pages/online/pages/man3/mkstemp.3.html
+ (NSString *)pathInTempDirectory:(NSString *)fileNameOrTemplate withRandomName:(BOOL)generateRandomName {
	if (!generateRandomName) {
		return [NSTemporaryDirectory() stringByAppendingPathComponent:fileNameOrTemplate];
	} else {
		NSString *tempFileTemplate = [NSTemporaryDirectory()
				stringByAppendingPathComponent:fileNameOrTemplate];

		const char *tempFileTemplateCString =
				[tempFileTemplate fileSystemRepresentation];

		char *tempFileNameCString = (char *) malloc(strlen(tempFileTemplateCString) + 1);
		strcpy(tempFileNameCString, tempFileTemplateCString);
		int fileDescriptor = mkstemps(tempFileNameCString, 4);

		// no need to keep it open
		close(fileDescriptor);

		if (fileDescriptor == -1) {
//			DDLogError(@"Error while creating tmp file");
			free(tempFileNameCString);
			return nil;
		}

		NSString *tempFileName = [[NSFileManager defaultManager]
				stringWithFileSystemRepresentation:tempFileNameCString
											length:strlen(tempFileNameCString)];

		free(tempFileNameCString);

		return tempFileName;
	}
}

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePath {
	return [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:filePath]];
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {
	NSError *error = nil;

	BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES]
								  forKey:NSURLIsExcludedFromBackupKey error:&error];

	if (!success) {
//		DDLogError(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
	}

	return success;
}

@end