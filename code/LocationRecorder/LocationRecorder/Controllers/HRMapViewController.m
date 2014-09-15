//
// Created by Nimrod Astrahan on 8/20/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "HRMapViewController.h"
#import "GMSMapView.h"
#import "HRRecordingSession.h"
#import "GMSCameraPosition.h"
#import "HRRecordingSessionsManager.h"
#import "GMSMutablePath.h"
#import "GMSPolyline.h"
#import "HRecordingSessionSnapshot.h"
#import "AEAudioFilePlayer.h"
#import "GMSMarker.h"

@interface HRMapViewController ()

#pragma mark Services

@property (nonatomic, strong) HRRecordingSessionsManager *sessionsManager;

#pragma mark Data

@property (nonatomic, weak) GMSPolyline *displayedPolyline;
@property (nonatomic, strong) NSArray *snapshots;
@property (nonatomic, weak) GMSMarker *displayedMarker;

#pragma mark Views

@property (nonatomic, weak) GMSMapView *mapView;
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation HRMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		self.sessionsManager = [HRRecordingSessionsManager instance];

		@weakify(self);
		[[[RACAble(self.sessionsManager.currentSession)
				map:^id(HRRecordingSession *selectedSession) {
					@strongify(self);
					NSArray *snapshots = [self.sessionsManager snapshotsOfSession:selectedSession];
					self.snapshots = snapshots;
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

		dispatch_source_t timer = dispatch_source_create(
				DISPATCH_SOURCE_TYPE_TIMER,
				0,
				0,
				dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

		if (timer) {
			dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 1ull * NSEC_PER_SEC, 0);
			dispatch_source_set_event_handler(timer, ^{
				@strongify(self);
				double currentTime = self.sessionsManager.player.currentTime;
				if (self.snapshots && currentTime > 0) {
					__block HRRecordingSessionSnapshot *closestSnapshot;
					__block int minimumDiff = INT32_MAX;
					double roundedCurrentTime = round(currentTime);

					[self.snapshots enumerateObjectsUsingBlock:^(HRRecordingSessionSnapshot *snapshot, NSUInteger idx, BOOL *stop) {
						double roundedSnapshotTimestamp = round(snapshot.timestamp / 2.0);
						if (roundedCurrentTime == roundedSnapshotTimestamp) {
							closestSnapshot = snapshot;
							*stop = YES;
						}

						int diff = abs((int) (roundedCurrentTime - roundedSnapshotTimestamp));
						if (diff < minimumDiff) {
							minimumDiff = diff;
							closestSnapshot = snapshot;
						}
					}];

					NSLog(@"Current time is %f, closest location is timestamp %f ", currentTime, closestSnapshot.timestamp);
					//GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithTarget:closestSnapshot.location.coordinate zoom:self.mapView.camera.zoom];

					dispatch_async(dispatch_get_main_queue(), ^{
						@strongify(self);
						//self.mapView.camera = cameraPosition;
						self.displayedMarker.map = nil;
						GMSMarker *marker = [[GMSMarker alloc] init];
						marker.position = closestSnapshot.location.coordinate;
						NSInteger ti = (NSInteger)closestSnapshot.timestamp;
						NSInteger seconds = ti % 60;
						NSInteger minutes = (ti / 60) % 60;
						NSInteger hours = (ti / 3600);
						marker.snippet = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
						marker.appearAnimation = kGMSMarkerAnimationPop;
						marker.map = self.mapView;
						self.displayedMarker = marker;
					});
				}
			});
			dispatch_resume(timer);
		}

		self.timer = timer;
	}

	return self;
}


- (NSString *)title {
	return @"Map";
}

- (void)viewDidLoad {
	GMSCameraPosition *cameraPosition = [GMSCameraPosition cameraWithLatitude:32.0833 longitude:34.8000 zoom:15];
	GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectZero camera:cameraPosition];
	mapView.myLocationEnabled = YES;

	self.mapView = mapView;
	self.displayedPolyline.map = mapView;
	self.view = mapView;
}

@end