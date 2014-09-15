//
// Created by Nimrod Astrahan on 8/16/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "HRRecordingSessionsViewController.h"
#import "HRRecordingSession.h"
#import "HRRecordingSessionsManager.h"
#import "ViewUtils.h"

@interface HRRecordingSessionsViewController() <TLIndexPathControllerDelegate>

@property (nonatomic, strong) TLIndexPathController *indexPathController;
@property (nonatomic, strong) HRRecordingSessionsManager *sessionsManager;

@end

@implementation HRRecordingSessionsViewController

- (id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self) {
	}

	return self;
}

- (NSString *)title {
	return @"Recordings";
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.indexPathController = [[TLIndexPathController alloc] init];
	self.sessionsManager = [HRRecordingSessionsManager instance];
	self.indexPathController.items = [self.sessionsManager allRecordingSessions];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.indexPathController.dataModel.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.indexPathController.dataModel numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HRRecordingSessionsViewCellIdentifier];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:HRRecordingSessionsViewCellIdentifier];
	}

	HRRecordingSession *recordingSession = [self.indexPathController.dataModel itemAtIndexPath:indexPath];
	cell.textLabel.text = recordingSession.name;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", recordingSession.startDate, recordingSession.endDate];

	return cell;
}

- (void)controller:(TLIndexPathController *)controller didUpdateDataModel:(TLIndexPathUpdates *)updates {
	[updates performBatchUpdatesOnTableView:self.tableView withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	HRRecordingSession *selectedSession = [self.indexPathController.dataModel itemAtIndexPath:indexPath];
	self.sessionsManager.currentSession = selectedSession;
}

@end