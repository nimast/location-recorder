//
// Created by Nimrod Astrahan on 8/6/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

@interface HRRecordingSession : NSObject

- (instancetype)initWithName:(NSString *)name;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@end