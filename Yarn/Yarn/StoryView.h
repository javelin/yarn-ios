//
//  StoryView.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StoryViewController;

@interface StoryView : UIView

@property (nonatomic, strong) StoryViewController *controller;

- (id)initWithController:(StoryViewController *)controller;

@end
