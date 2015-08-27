//
//  StorySettingsPageViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoryViewController.h"

@interface StorySettingsPageViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, readonly) StoryViewController *storyViewController;

@property (nonatomic, readonly) UIPickerView *formatPickerView;
@property (nonatomic, readonly) UIPickerView *proofingFormatPickerView;
@property (nonatomic, readonly) UITextView *statsTextView;
@property (nonatomic, readonly) UITextField *titleTexField;

- (instancetype)initWithStoryViewController:(StoryViewController *)storyViewController;

@end
