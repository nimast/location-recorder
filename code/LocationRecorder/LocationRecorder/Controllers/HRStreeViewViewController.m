//
// Created by Nimrod Astrahan on 9/13/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <Google-Maps-iOS-SDK/GoogleMaps/GMSMapView.h>
#import <Google-Maps-iOS-SDK/GoogleMaps/GMSCameraPosition.h>
#import <Google-Maps-iOS-SDK/GoogleMaps/GMSPolyline.h>
#import <Google-Maps-iOS-SDK/GoogleMaps/GMSMutablePath.h>
#import "HRStreeViewViewController.h"
#import "GMSPath.h"
#import "HRecordingSessionSnapshot.h"
#import "HRRecordingSession.h"
#import "HRRecordingSessionsManager.h"

@interface HRStreeViewViewController ()

#pragma mark Services

@property (nonatomic, strong) HRRecordingSessionsManager *sessionsManager;

#pragma mark Data

@property (nonatomic, weak) GMSPolyline *displayedPolyline;

#pragma mark Views

@property (nonatomic, weak) GMSMapView *mapView;

@end

@implementation HRStreeViewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		self.sessionsManager = [HRRecordingSessionsManager instance];

		@weakify(self);
		[[[RACAble(self.sessionsManager.currentSession)
				map:^id(HRRecordingSession *selectedSession) {
					@strongify(self);
					NSArray *snapshots = [self.sessionsManager snapshotsOfSession:selectedSession];
					GMSMutablePath *path = [GMSMutablePath path];

					[snapshots enumerateObjectsUsingBlock:^(HRRecordingSessionSnapshot *snapshot, NSUInteger idx, BOOL *stop) {
						[path addCoordinate:snapshot.location.coordinate];
					}];

					return path;
				}]
				deliverOn:[RACScheduler mainThreadScheduler]]
				subscribeNext:^(GMSMutablePath *path) {
					@strongify(self);
					NSLog(@"Displaying path with length %f", [path lengthOfKind:kGMSLengthGeodesic]);
					self.displayedPolyline.map = nil;
					GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
					polyline.strokeColor = [UIColor redColor];
					polyline.strokeWidth = 1.f;
					polyline.map = self.mapView;
					self.displayedPolyline = polyline;
				}];
	}

	return self;
}


- (NSString *)title {
	return @"Map";
}

- (void)viewDidLoad {
	GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:31 longitude:35 zoom:6];
	GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectZero camera:cameraPosition];
	mapView.myLocationEnabled = YES;

	self.mapView = mapView;
	self.displayedPolyline.map = mapView;
	self.view = mapView;
}

@end