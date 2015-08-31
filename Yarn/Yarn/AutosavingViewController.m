//
//  AutosavingViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "AutosavingViewController.h"
#import "ViewUtils.h"

@interface AutosavingViewController ()

@property (nonatomic, strong) UILabel *autosaveLabel;

@end

@implementation AutosavingViewController

- (id)init {
    self = [super init];
    if (self) {
        _autosaveTimer = nil;
        [self setView:[UIView new]];
        INIT_VIEW(UILabel, _autosaveLabel, [self view]);
        [_autosaveLabel setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.7]];
        [_autosaveLabel setFont:[UIFont systemFontOfSize:10.0]];
        [_autosaveLabel setHidden:YES];
        [_autosaveLabel setText:_LS(@"Autosaving...")];
        [_autosaveLabel setTextAlignment:NSTextAlignmentCenter];
        [_autosaveLabel setTextColor:[UIColor whiteColor]];
        [_autosaveLabel sizeToFit];
        CONSTRAINT_EQ([self view], _autosaveLabel, Top, [self view], Top, 1.0, 0.0);
        CONSTRAINT_EQ([self view], _autosaveLabel, Left, [self view], Left, 1.0, 0.0);
        CONSTRAINT_EQ([self view], _autosaveLabel, Right, [self view], Right, 1.0, 0.0);
        CONSTRAINT_EQ([self view], _autosaveLabel, Height, nil, Height, 1.0, CGRectGetHeight([_autosaveLabel frame]));
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)autosave {
    [self showAutosaveLabel:YES];
    DispatchMainAfter(1.5, ^{
        [self showAutosaveLabel:NO];
    });
}

- (NSTimeInterval)autosaveInterval {
    return 20.0;
}

- (void)dismissAlertView:(UIAlertView *)alertView {
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)invalidateAutosaveTimer {
    if (_autosaveTimer) {
        [_autosaveTimer invalidate];
        _autosaveTimer = nil;
    }
}

- (void)showAutosaveLabel:(BOOL)show {
    [_autosaveLabel setHidden:!show];
    if (show) {
        [[self view] bringSubviewToFront:_autosaveLabel];
    }
}

- (void)startAutosaveTimer {
    [self invalidateAutosaveTimer];
    if (!self.autosaveTimer) {
        NSLog(@"Starting auto save timer....");
        _autosaveTimer =
        [NSTimer scheduledTimerWithTimeInterval:[self autosaveInterval]
                                         target:self
                                       selector:@selector(autosave)
                                       userInfo:nil
                                        repeats:NO];
    }
}

@end
