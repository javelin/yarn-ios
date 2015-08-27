//
//  SegmentedPagedViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "SegmentedPagedViewController.h"
#import "ViewUtils.h"

@interface SegmentedPagedViewController () {
    NSInteger _lastSelectedIndex;
}

@end

@implementation SegmentedPagedViewController

- (instancetype)initWithControllers:(NSArray *)controllers {
    self = [super init];
    if (self) {
        _controllers = [NSArray arrayWithArray:controllers];
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[controllers count]];
        for (UIViewController *controller in controllers) {
            [titles addObject:[controller title]];
        }
        _titles = [NSArray arrayWithArray:titles];
        _pageViewController =
        [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                        navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                      options:@{}];
        [self addChildViewController:_pageViewController];
        [self createViews];
        [self addConstraints];
    }
    
    return self;
}

- (void)addConstraints {
    CONSTRAINT_EQ([self view], _segmentedControl, Top, [self view], Top, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _segmentedControl, CenterX, [self view], CenterX, 1.0, 0.0);
    CONSTRAINT_EQ([self view], [_pageViewController view], Top, _segmentedControl, Bottom, 1.0, 10.0);
    CONSTRAINT_EQ([self view], [_pageViewController view], Left, [self view], Left, 1.0, 10.0);
    CONSTRAINT_EQ([self view], [_pageViewController view], Right, [self view], Right, 1.0, -10.0);
    CONSTRAINT_EQ([self view], [_pageViewController view], Bottom, [self view], Bottom, 1.0, -10.0);
}

- (void)createViews {
    [self setView:[UIView new]];
    [[self view] setBackgroundColor:[UIColor whiteColor]];
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:_titles];
    [_segmentedControl addTarget:self
                          action:@selector(segmentValueChanged:)
                forControlEvents:UIControlEventValueChanged];
    
    ADD_SUBVIEW([self view], _segmentedControl);
    ADD_SUBVIEW([self view], [_pageViewController view]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)segmentValueChanged:(UISegmentedControl *)segmentedControl {
    UIViewController *controller = [[self controllers] objectAtIndex:[segmentedControl selectedSegmentIndex]];
    UIPageViewControllerNavigationDirection dir = (_lastSelectedIndex < [segmentedControl selectedSegmentIndex] ?
                                                   UIPageViewControllerNavigationDirectionForward:
                                                   UIPageViewControllerNavigationDirectionReverse);
    _lastSelectedIndex = [segmentedControl selectedSegmentIndex];
    [_pageViewController setViewControllers:@[controller]
                                  direction:dir
                                   animated:YES
                                 completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([_segmentedControl selectedSegmentIndex] == -1) {
        _lastSelectedIndex = 0;
        [_segmentedControl setSelectedSegmentIndex:0];
        UIViewController *controller = [[self controllers] objectAtIndex:0];
        [_pageViewController setViewControllers:@[controller]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    }
}

@end
