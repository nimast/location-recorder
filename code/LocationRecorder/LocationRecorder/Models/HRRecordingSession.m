//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <MacTypes.h>
#import <CoreLocation/CoreLocation.h>
#import "HRRecordingSession.h"

@implementation HRRecordingSession

- (instancetype)initWithName:(NSString *)name {
	if ((self = [super init]) == nil) {
		return nil;
	}

	self.name = name;

	return self;
}

@end