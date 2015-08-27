//
//  ViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/12/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SegmentedPagedViewController.h"
#import "WebViewController.h"

@protocol EntityList <NSObject>

- (void)addNewEntity;
- (BOOL)shouldReload;
- (void)sortObjects;
- (NSString *)saveDir;

@end

@interface HomeViewController : SegmentedPagedViewController

@property (nonatomic, readonly) WebViewController *faqViewController;
@property (nonatomic, readonly) WebViewController *helpViewController;

@property (nonatomic, readonly) NSArray *storyFormats;
@property (nonatomic, readonly) NSArray *proofingFormats;

+ (instancetype)sharedInstance;

@end

