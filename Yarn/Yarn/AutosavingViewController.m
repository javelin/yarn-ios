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

@end

@implementation AutosavingViewController

- (id)init {
    self = [super init];
    if (self) {
        _autosaveTimer = nil;
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)autosave {
    AlertAndDismissInfo(nil, _LS(@"Autosaving..."), 0.5, self);
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
