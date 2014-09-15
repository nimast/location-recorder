//
// Created by Nimrod Astrahan on 8/20/14.
// Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "HRRecordingSessionsViewCell.h"
#import "HRRecordingSession.h"
#import "ViewUtils.h"

@interface HRRecordingSessionsViewCell ()

@property (nonatomic, strong) HRRecordingSession *recordingSession;

@end

@implementation HRRecordingSessionsViewCell

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		@weakify(self);
		[RACAble(self.recordingSession) subscribeNext:^(id x) {
			@strongify(self);
			[self.subviews enumerateObjectsUsingBlock:^(UIView *subView, NSUInteger idx, BOOL *stop) {
				[subView removeFromSuperview];
			}];

			[self setup];
		}];
	}

	return self;
}

- (void)setup {

}

@end