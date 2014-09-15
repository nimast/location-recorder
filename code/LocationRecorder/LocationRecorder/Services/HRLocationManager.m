//
// Created by Nimrod Astrahan on 8/9/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "HRLocationManager.h"

@interface HRLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation HRLocationManager

- (id)init {
	self = [super init];
	if (self) {
		self.locationManager = [[CLLocationManager alloc] init];
		self.locationManager.delegate = self;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		[self.locationManager startUpdatingLocation];
	}

	return self;
}

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations {
	// If it's a relatively recent event, turn off updates to save power.
	CLLocation *location = [locations lastObject];
	self.currentLocation = location;
}

@end