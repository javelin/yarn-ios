//
//  ViewUtils.h
//  PickYourFate
//
//  Created by Mark Jundo Documento on 5/6/14.
//  Copyright (c) 2014 Blue Byte Games. All rights reserved.
//

#ifndef Yarn_ViewUtils_h
#define Yarn_ViewUtils_h

#import <UIKit/UIKit.h>
#import "NavigationController.h"
#import "Utils.h"

#define CREATE_VIEW(cls, view, superview)   cls *view = [[cls alloc] init]; \
    view.translatesAutoresizingMaskIntoConstraints = NO;\
    [superview addSubview:view]
#define INIT_VIEW(cls, view, superview)     view = [[cls alloc] init]; \
    view.translatesAutoresizingMaskIntoConstraints = NO;\
    [superview addSubview:view]
#define CONSTRAINT_EQ(view, view1, attrib1, view2, attrib2, mult, constant_) \
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttribute##attrib1 \
    relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttribute##attrib2 \
    multiplier:mult constant:constant_]]
#define CONSTRAINT_GEQ(view, view1, attrib1, view2, attrib2, mult, constant_) \
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttribute##attrib1 \
    relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:view2 attribute:NSLayoutAttribute##attrib2 \
    multiplier:mult constant:constant_]]
#define CONSTRAINT_LEQ(view, view1, attrib1, view2, attrib2, mult, constant_) \
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttribute##attrib1 \
    relatedBy:NSLayoutRelationLessThanOrEqual toItem:view2 attribute:NSLayoutAttribute##attrib2 \
    multiplier:mult constant:constant_]]

#define INIT_CONSTRAINT_EQ(constraint, view, view1, attrib1, view2, attrib2, mult, constant_) \
    constraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttribute##attrib1 \
    relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttribute##attrib2 \
    multiplier:mult constant:constant_]; \
    [view addConstraint:constraint]
#define INIT_CONSTRAINT_GEQ(constraint, view, view1, attrib1, view2, attrib2, mult, constant_) \
    constraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttribute##attrib1 \
    relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:view2 attribute:NSLayoutAttribute##attrib2 \
    multiplier:mult constant:constant_]; \
    [view addConstraint:constraint]
#define INIT_CONSTRAINT_LEQ(constraint, view, view1, attrib1, view2, attrib2, mult, constant_) \
    constraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttribute##attrib1 \
    relatedBy:NSLayoutRelationLessThanOrEqual toItem:view2 attribute:NSLayoutAttribute##attrib2 \
    multiplier:mult constant:constant_]; \
    [view addConstraint:constraint]

#define CLEAR_CONSTRAINTS(view) [view removeConstraints:view.constraints]
#define ADD_SUBVIEW(superview, view)    view.translatesAutoresizingMaskIntoConstraints = NO;\
    [superview addSubview:view]

#define CREATE_VIEW_FILL(cls, view, superview) CREATE_VIEW(cls, view, superview); \
    CONSTRAINT_EQ(superview, view, Leading, superview, Leading, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Top, superview, Top, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Trailing, superview, Trailing, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Bottom, superview, Bottom, 1.0, 0.0)
#define INIT_VIEW_FILL(cls, view, superview) INIT_VIEW(cls, view, superview); \
    CONSTRAINT_EQ(superview, view, Leading, superview, Leading, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Top, superview, Top, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Trailing, superview, Trailing, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Bottom, superview, Bottom, 1.0, 0.0)
#define ADD_SUBVIEW_FILL(superview, view)    view.translatesAutoresizingMaskIntoConstraints = NO;\
    [superview addSubview:view]; \
    CONSTRAINT_EQ(superview, view, Leading, superview, Leading, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Top, superview, Top, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Trailing, superview, Trailing, 1.0, 0.0); \
    CONSTRAINT_EQ(superview, view, Bottom, superview, Bottom, 1.0, 0.0)

#define INIT_SEARCHBAR(searchBar, placeholdertext) searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)]; \
    if ([searchBar respondsToSelector:@selector(setTranslucent:)]) { searchBar.translucent = NO; } \
    if ([searchBar respondsToSelector:@selector(setBarTintColor:)]) { searchBar.barTintColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.78 alpha:1.0]; } \
    for (UIView* view in searchBar.subviews) { \
        if ([NSStringFromClass([view class]) isEqualToString:@"UISearchBarBackground"]) { \
        [view removeFromSuperview]; } } \
    searchBar.backgroundColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.78 alpha:1.0]; \
    searchBar.placeholder = NSLocalizedString(placeholdertext, nil)

#define PAGE_TURN(view, oldView) [UIView beginAnimations:@"Flip" context:nil]; \
    [UIView setAnimationDuration:1.0]; \
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut]; \
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:view cache:YES]; \
    [oldView removeFromSuperview]; \
    [UIView commitAnimations]

#define HIDE_WAIT() [(NavigationController *)self.navigationController hideActivityIndicator]
#define SHOW_WAIT() [(NavigationController *)self.navigationController showActivityIndicator]

#define ALERT(__title, __message, __presenter) {UIAlertController *alertController =\
[UIAlertController alertControllerWithTitle:(__title) message:(__message) preferredStyle:UIAlertControllerStyleAlert];\
[alertController addAction:[UIAlertAction actionWithTitle:_LS(@"Close") style:UIAlertActionStyleDefault handler:nil]];\
[__presenter presentViewController:alertController animated:YES completion:nil];}

#define IS_IPAD() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

UIAlertController *AlertAndDismissInfo(NSString *title,
                                       NSString *message,
                                       double secondsToShow,
                                       UIViewController *presenter);
UIAlertController *AlertError(NSString *message,
                              UIViewController *presenter);
UIAlertController *AlertInfo(NSString *title,
                             NSString *message,
                             NSString *actionTitle,
                             UIViewController *presenter);
UIAlertController *AlertQuestion(NSString *title,
                                 NSString *message,
                                 NSString *cancelTitle,
                                 NSString *actionTitle,
                                 BOOL destructive,
                                 void (^handler)(UIAlertAction *action),
                                 UIViewController *presenter);
UIAlertController *AlertQuestionWithCancelHandler(NSString *title,
                                                  NSString *message,
                                                  NSString *cancelTitle,
                                                  void (^cancelHandler)(UIAlertAction *action),
                                                  NSString *actionTitle,
                                                  BOOL destructive,
                                                  void (^handler)(UIAlertAction *action),
                                                  UIViewController *presenter);

void CreateBackButtonOn(UINavigationItem* navigationItem, id target, SEL action);
UIButton* CreateBackButton();

void SetBorderWidth(UIView *view, CGFloat borderWidth);
void SetBorderColor(UIView *view, UIColor *color);
void SetRoundedCorners(UIView *view, CGFloat radius);

void SetBarButtonItemImageName(UIBarButtonItem *bbi, NSString *name);
void EnableBarButtonItem(UIBarButtonItem *bbi, BOOL set);

#endif
