//
// Created by Nimrod Astrahan on 8/9/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//


@class CLLocation;
#ifndef __HRecordingSessionSnapshot_H_
#define __HRecordingSessionSnapshot_H_

@interface HRRecordingSessionSnapshot : NSObject

@property (nonatomic, assign) double timestamp;
@property (nonatomic, strong) CLLocation *location;

@end

#endif //__HRecordingSessionSnapshot_H_
