//
//  StoryViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "AutosavingViewController.h"
#import "PassageView.h"
#import "PassageEditorViewController.h"
#import "Story.h"
#import "StoryFormat.h"

@interface StoryViewController : AutosavingViewController <PassageViewDelegate, PassageEditorViewControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, readonly) Story *story;
@property (nonatomic, readonly) NSDictionary *passageViews;
@property (nonatomic) BOOL snapsToGrid;
@property (nonatomic, readonly, weak) NSArray *formats;
@property (nonatomic, readonly, weak) NSArray *proofingFormats;
@property (nonatomic, weak) StoryFormat *proofingFormat;

- (id)initWithStory:(Story *)story
            formats:(NSArray *)formats
    proofingFormats:(NSArray *)proofingFormats
       showSettings:(BOOL)showSettings
         completion:(void (^)(Story *story))handler;
- (PassageView *)getPassageViewWithName:(NSString *)name;
- (PassageView *)getPassageViewWithId:(NSInteger)Id;

@end
