//
//  StatisticsViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/26/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Story;

@interface StatisticsViewController : UIViewController

@property (nonatomic, readonly) Story *story;
@property (nonatomic, readonly) UITextView *textView;

- (instancetype)initWithStory:(Story *)story;

@end
