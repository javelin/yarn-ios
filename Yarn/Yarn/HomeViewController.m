//
//  ViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/12/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "Constants.h"
#import "HomeViewController.h"
#import "StoriesViewController.h"
#import "StoryFormatsViewController.h"
#import "ViewUtils.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (instancetype)init {
    self = [super initWithControllers:@[[StoriesViewController new],
                                        [[StoryFormatsViewController alloc]
                                         initWithBuiltInFormats:@[@"Harlowe",
                                                                  @"Snowman",
                                                                  @"SugarCube"]
                                         proofing:NO],
                                        [[StoryFormatsViewController alloc]
                                         initWithBuiltInFormats:@[@"Paperthin"]
                                         proofing:YES]]];
    if (self) {
        UIBarButtonItem *barButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:_LS(@"Menu")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleMenu)];
        [[self navigationItem] setLeftBarButtonItem:barButtonItem];
        
        barButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(handleCreateNew)];
        [[self navigationItem] setRightBarButtonItem:barButtonItem];
    }
    
    return self;
}

+ (instancetype)sharedInstance {
    static HomeViewController *sharedInstance;
    if (!sharedInstance) {
        sharedInstance = [HomeViewController new];
    }
    
    return sharedInstance;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)proofingFormats {
    StoryFormatsViewController *storyFormatsController = [[self controllers] objectAtIndex:2];
    return [storyFormatsController storyFormats];
}

- (NSArray *)storyFormats {
    StoryFormatsViewController *storyFormatsController = [[self controllers] objectAtIndex:1];
    return [storyFormatsController storyFormats];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setTitle:[AppName() stringByAppendingFormat:@" v%@", AppVersion()]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setTitle:@""];
}

#pragma mark Handlers
- (void)handleCreateNew {
    id<EntityList> obj = [[self controllers] objectAtIndex:[[self segmentedControl] selectedSegmentIndex]];
    NSAssert([obj respondsToSelector:@selector(addNewEntity)],
             @"Controller must implement addNewEntity.");
    [obj performSelector:@selector(addNewEntity)];
}

- (void)handleMenu {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:[self title]
                                        message:_LS(@"")
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Help")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                [self showHelp];
                            }]];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"FAQ")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                [self showFAQ];
                            }]];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"About")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                [self showAbout];
                            }]];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Cancel")
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    
    // For iPad
    UIPopoverPresentationController *popoverController =
    [alertController popoverPresentationController];
    [popoverController setBarButtonItem:[[self navigationItem] leftBarButtonItem]];
    [popoverController setPermittedArrowDirections:UIPopoverArrowDirectionAny];
    
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

- (void)showAbout {
    AlertInfo(_LS(@"About"),
              [NSString stringWithFormat:_LS(@"__About Format__"),
               AppName(),
               AppVersion(),
               TwineVersion()],
              _LS(@"Close"),
              self);
}

- (void)showFAQ {
    if (!_faqViewController) {
        NSString *faq = [NSString stringWithContentsOfURL:[[NSBundle mainBundle]
                                                           URLForResource:@"faq"
                                                           withExtension:@"html"]
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
        faq = [NSString stringWithFormat:faq,
               AppName(),
               AppVersion(),
               TwineVersion(),
               BUNDLE_VALUE((NSString *)kBundleYarnSourceURL),
               BUNDLE_VALUE((NSString *)kBundleMyEmail)];
        _faqViewController =
        [WebViewController webViewControllerWithHtml:faq];
        [_faqViewController setTitle:_LS(@"FAQ")];
    }
    [[self navigationController] pushViewController:_faqViewController
                                           animated:YES];
}

- (void)showHelp {
    if (!_helpViewController) {
        _helpViewController =
        [WebViewController webViewControllerWithURL:[[NSBundle mainBundle]
                                                     URLForResource:@"help"
                                                     withExtension:@"html"]];
        [_helpViewController setTitle:_LS(@"Help")];
    }
    [[self navigationController] pushViewController:_helpViewController
                                           animated:YES];
}

@end
