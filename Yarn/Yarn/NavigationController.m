//
//  NavigationController.m
//  Yarn
//
//  Created by Mark Jundo P. Documento on 1/25/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import "NavigationController.h"
#import "HomeViewController.h"
#import "ViewUtils.h"

@interface NavigationController ()

@end

@implementation NavigationController

-(id)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        _activityIndicator = nil;
        if ([[self navigationBar] respondsToSelector:@selector(setTranslucent:)]) {
            [[self navigationBar] setTranslucent:NO];
        }
    }
    return self;
}

-(BOOL)shouldAutorotate {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (void)hideActivityIndicator {
    if (_activityIndicator) {
        [_activityIndicator stopAnimating];
    }
}

- (void)showActivityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc]
                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_activityIndicator setHidesWhenStopped:YES];
        [_activityIndicator setAlpha:0.4f];
        [_activityIndicator setBackgroundColor:[UIColor blackColor]];
        
        //SetRoundedCorners(_activityIndicator, 10.0f);
        //ADD_SUBVIEW([self view], _activityIndicator);
        //CONSTRAINT_EQ([self view], _activityIndicator, CenterX, [self view], CenterX, 1.0, 0.0);
        //CONSTRAINT_EQ([self view], _activityIndicator, CenterY, [self view], CenterY, 1.0, 0.0);
        //CONSTRAINT_EQ([self view], _activityIndicator, Width, nil, Width, 1.0, 100.0);
        //CONSTRAINT_EQ([self view], _activityIndicator, Height, nil, Height, 1.0, 100.0);

        ADD_SUBVIEW_FILL([self view], _activityIndicator);
    }
    else {
        [_activityIndicator setHidden:NO];
    }
    
    [[self view] bringSubviewToFront:_activityIndicator];
    [_activityIndicator startAnimating];
}

@end
