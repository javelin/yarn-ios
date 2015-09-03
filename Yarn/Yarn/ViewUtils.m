//
//  ViewUtils.m
//  PickYourFate
//
//  Created by Mark Jundo Documento on 5/6/14.
//  Copyright (c) 2014 Blue Byte Games. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#include "ViewUtils.h"

UIAlertController *AlertAndDismissInfo(NSString *title,
                                       NSString *message,
                                       double secondsToShow,
                                       UIViewController *presenter) {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    NSCAssert(presenter != nil, @"Presenting view controller should not be nil.");
    [presenter presentViewController:alertController
                            animated:YES
                          completion:nil];
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW,
                                          (dispatch_time_t)round(secondsToShow * (double)NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [alertController dismissViewControllerAnimated:YES completion:nil];
    });
    return alertController;
}

UIAlertController *AlertError(NSString *message,
                              UIViewController *presenter) {
    return AlertInfo(_LS(@"Error"),
                     message,
                     _LS(@"Close"),
                     presenter);
}

UIAlertController *AlertInfo(NSString *title,
                             NSString *message,
                             NSString *cancelTitle,
                             UIViewController *presenter) {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:
     [UIAlertAction actionWithTitle:cancelTitle
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    if (presenter) {
        [presenter presentViewController:alertController
                                animated:YES
                              completion:nil];
    }
    return alertController;
}

UIAlertController *AlertQuestion(NSString *title,
                                 NSString *message,
                                 NSString *cancelTitle,
                                 NSString *actionTitle,
                                 BOOL destructive,
                                 void (^handler)(UIAlertAction *action),
                                 UIViewController *presenter) {
    UIAlertController *alertController = AlertInfo(title, message, cancelTitle, nil);
    [alertController addAction:
     [UIAlertAction actionWithTitle:actionTitle
                              style:(destructive ?
                                     UIAlertActionStyleDestructive:
                                     UIAlertActionStyleDefault)
                            handler:handler]];
    if (presenter) {
        [presenter presentViewController:alertController
                                animated:YES
                              completion:nil];
    }
    return alertController;
}

UIAlertController *AlertQuestionWithCancelHandler(NSString *title,
                                                  NSString *message,
                                                  NSString *cancelTitle,
                                                  void (^cancelHandler)(UIAlertAction *action),
                                                  NSString *actionTitle,
                                                  BOOL destructive,
                                                  void (^handler)(UIAlertAction *action),
                                                  UIViewController *presenter) {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:
     [UIAlertAction actionWithTitle:cancelTitle
                              style:UIAlertActionStyleCancel
                            handler:cancelHandler]];
    [alertController addAction:
     [UIAlertAction actionWithTitle:actionTitle
                              style:(destructive ?
                                     UIAlertActionStyleDestructive:
                                     UIAlertActionStyleDefault)
                            handler:handler]];
    if (presenter) {
        [presenter presentViewController:alertController
                                animated:YES
                              completion:nil];
    }
    return alertController;
}

void CreateBackButtonOn(UINavigationItem* navigationItem, id target, SEL action) {
    UIButton* button = CreateBackButton();
    UIBarButtonItem* bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
    navigationItem.leftBarButtonItem = bbi;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

UIButton* CreateBackButton() {
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 52.0, 32.0)];
    [button setBackgroundImage:[UIImage imageNamed:@"navbar_logo_back.png"] forState:UIControlStateNormal];
    return button;
}

void SetBorderWidth(UIView *view, CGFloat borderWidth) {
    view.layer.borderWidth = borderWidth;
}

void SetBorderColor(UIView *view, UIColor *color) {
    view.layer.borderColor = [color CGColor];
}

void SetRoundedCorners(UIView *view, CGFloat radius) {
    view.layer.cornerRadius = radius;
    if ([view isKindOfClass:[UIImageView class]]) {
        view.layer.masksToBounds = YES;
    }
}
