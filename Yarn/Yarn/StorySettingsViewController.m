//
//  StorySettingsViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "MediaGalleryViewController.h"
#import "StatisticsViewController.h"
#import "StoryViewController.h"
#import "StorySettingsPageViewController.h"
#import "StorySettingsViewController.h"
#import "TextEditorViewController.h"
#import "ViewUtils.h"

@interface StorySettingsViewController ()

@property (nonatomic, strong) MediaGalleryViewController *mediaGalleryViewController;

@end

@implementation StorySettingsViewController

- (instancetype)initWithStoryViewController:(StoryViewController *)storyViewController {
    self = [super initWithControllers:@[[[StorySettingsPageViewController alloc]
                                         initWithStoryViewController:storyViewController],
                                        [[TextEditorViewController alloc] initWithTitle:_LS(@"Script") text:
                                         [[storyViewController story] script]],
                                        [[TextEditorViewController alloc] initWithTitle:_LS(@"Stylesheet") text:
                                         [[storyViewController story] stylesheet]],
                                        [[StatisticsViewController alloc] initWithStory:[storyViewController story]]]];
    if (self) {
        _storyViewController = storyViewController;
        
        _mediaGalleryViewController =
        [[MediaGalleryViewController alloc] initWithIFId:[[storyViewController story] ifId]];
        
        UIBarButtonItem *mediaBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"photo-album"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleMediaGallery)];
        
        [[self navigationItem] setRightBarButtonItem:mediaBarButtonItem];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setTitle:_LS(@"Story Settings")];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setTitle:@""];
}

- (void)willMoveToParentViewController:(nullable UIViewController *)parent {
    if (!parent) {
        SHOW_WAIT();
        [[_storyViewController story]
         save:^(Story *story) {
             HIDE_WAIT();
         }
         error:^(NSError *error) {
             HIDE_WAIT();
         }];
    }
}

#pragma mark Handlers
- (void)handleMediaGallery {
    [[self navigationController] pushViewController:_mediaGalleryViewController
                                           animated:YES];
}

@end
