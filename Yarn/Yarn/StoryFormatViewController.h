//
//  StoryFormatViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/27/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoryFormat.h"

@interface StoryFormatViewController : UIViewController

@property (nonatomic, readonly) UITextView *infoTextView;
@property (nonatomic, readonly) UIButton *defaultButton;

- (instancetype)initWithStoryFormat:(StoryFormat *)storyFormat;

@end
