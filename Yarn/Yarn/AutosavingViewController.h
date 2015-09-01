//
//  AutosavingViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface AutosavingViewController : UIViewController

@property (nonatomic, strong) NSTimer *autosaveTimer;

- (void)autosave;
- (NSTimeInterval)autosaveInterval;
- (void)invalidateAutosaveTimer;
- (void)saveData;
- (void)startAutosaveTimer;

@end
