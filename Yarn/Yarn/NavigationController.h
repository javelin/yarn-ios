//
//  NavigationController.h
//  Yarn
//
//  Created by Mark Jundo P. Documento on 1/25/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavigationController : UINavigationController

@property (nonatomic, readonly) UIActivityIndicatorView *activityIndicator;

- (void)hideActivityIndicator;
- (void)showActivityIndicator;

@end
