//
//  SegmentedPagedViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SegmentedPagedViewController : UIViewController

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, readonly) NSArray *controllers;
@property (nonatomic, readonly) NSArray *titles;

- (instancetype)initWithControllers:(NSArray *)controllers;

- (void)addConstraints;
- (void)createViews;
- (void)segmentValueChanged:(UISegmentedControl *)segmentedControl;

@end
