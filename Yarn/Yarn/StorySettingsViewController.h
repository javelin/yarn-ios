//
//  StorySettingsViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "SegmentedPagedViewController.h"

@class StoryViewController;

@interface StorySettingsViewController : SegmentedPagedViewController

@property (nonatomic, readonly) StoryViewController *storyViewController;

- (instancetype)initWithStoryViewController:(StoryViewController *)storyViewController;

@end
