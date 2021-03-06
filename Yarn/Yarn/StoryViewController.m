//
//  StoryViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "Constants.h"
#import "StorySettingsViewController.h"
#import "StoryView.h"
#import "StoryViewController.h"
#import "ViewUtils.h"
#import "Utils.h"
#import "WebViewController.h"

@interface StoryViewController () {
    void (^_completionHandler)(Story *story);
    NSMutableDictionary* _passageViews;
    BOOL _showSettings;
    BOOL _isClosing;
}

@property (nonatomic, strong) StoryView *storyView;
@property (nonatomic, strong) UILabel *snapToGridLabel;

@property (nonatomic, strong) MediaPickerViewController *mediaPickerViewController;
@property (nonatomic, strong) PassageEditorViewController *passageEditorViewController;

@property (nonatomic, strong) UIAlertController *createPassageController;
@property (nonatomic, strong) UIAlertController *menuController;
@property (nonatomic, strong) UIAlertController *exportArchiveMenuController;
@property (nonatomic, strong) UIAlertController *exportHtmlMenuController;

@property (nonatomic, strong) UIDocumentInteractionController *exportInteractionController;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation StoryViewController

static CGFloat GridSpacing = 140.0;

- (id)initWithStory:(Story *)story
            formats:(NSArray *)formats
    proofingFormats:(NSArray *)proofingFormats
       showSettings:(BOOL)showSettings
         completion:(void (^)(Story *))handler {
    self = [super init];
    if (self) {
        _story = story;
        _completionHandler = handler;
        
        _formats = formats;
        _proofingFormats = proofingFormats;
        
        _createPassageController = nil;
        _exportArchiveMenuController = nil;
        _exportHtmlMenuController = nil;
        _menuController = nil;
        
        _isClosing = NO;
        _showSettings = showSettings;
        
        
        _proofingFormat = nil;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *proofingFormat = [userDefaults objectForKey:(NSString *)kYarnKeyProofingFormat];
        if (![proofingFormat notEmpty]) {
            proofingFormat = (NSString *)kYarnDefaultProofingFormat;
        }
        for (StoryFormat *format in _proofingFormats) {
            if ([[format name] isEqualToString:proofingFormat]) {
                _proofingFormat = format;
                break;
            }
        }
        
        if (!_proofingFormat) {
            _proofingFormat = [_proofingFormats firstObject];
        }
        
        _passageViews = [NSMutableDictionary dictionary];
        NSNumber *n = [userDefaults objectForKey:(NSString *)kYarnKeySnapToGrid];
        _snapsToGrid = n ? [n boolValue]:YES;
        
        [self createViews];
        
        [self setTitle:story.name];
        
        UIBarButtonItem* add =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(handleCreateNewPassage)];
        
        UIBarButtonItem* menu =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleMenu)];
        
        if (IS_IPAD()) {
            UIBarButtonItem* play =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                          target:self
                                                          action:@selector(handleTestPlay)];
            [[self navigationItem] setRightBarButtonItems:@[menu, play, add]];
            
        }
        else {
            [[self navigationItem] setRightBarButtonItems:@[menu, add]];
        }
        
        _mediaPickerViewController =
        [[MediaPickerViewController alloc] initWithIFId:[_story ifId]];
    }
    
    return self;
}

- (void)createViews {
    [[self view] setBackgroundColor:[UIColor lightGrayColor]];
    _storyView = [[StoryView alloc] initWithController:self];
    _scrollView = [[UIScrollView alloc] init];
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [_scrollView setMaximumZoomScale:2.0];
    [_scrollView setMinimumZoomScale:0.25];
    [_scrollView setClipsToBounds:YES];
    [_scrollView setCanCancelContentTouches:NO];
    [_scrollView setDelegate:self];
    [_scrollView addSubview:_storyView];
    for (UIGestureRecognizer *gestureRecognizer in [_scrollView gestureRecognizers]) {
        if ([gestureRecognizer  isKindOfClass:[UIPanGestureRecognizer class]]) {
            UIPanGestureRecognizer *panGR = (UIPanGestureRecognizer *) gestureRecognizer;
            [panGR setMinimumNumberOfTouches:2];
            [panGR setMaximumNumberOfTouches:2];
        }
    }
    ADD_SUBVIEW_FILL([self view], _scrollView);
    if (!IS_IPAD()) {
        [_scrollView setZoomScale:0.75];
    }
    
    INIT_VIEW(UILabel, _snapToGridLabel, [self view]);
    [_snapToGridLabel setBackgroundColor:[UIColor clearColor]];
    [_snapToGridLabel setFont:[UIFont boldSystemFontOfSize:
                               IS_IPAD() ? kYarnFontSizeSnapToGridIpad:kYarnFontSizeSnapToGrid]];
    [_snapToGridLabel setTextAlignment:NSTextAlignmentRight];
    [_snapToGridLabel setTextColor:[UIColor whiteColor]];
    [_snapToGridLabel setText:[@"Snap To Grid: " stringByAppendingString:_snapsToGrid ? @"On":@"Off"]];
    CONSTRAINT_EQ([self view], _snapToGridLabel, Left, [self view], Left, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _snapToGridLabel, Right, [self view], Right, 1.0, -10.0);
    CONSTRAINT_EQ([self view], _snapToGridLabel, Bottom, [self view], Bottom, 1.0, -10.0);
    
    CGFloat largestX = 0, largestY = 0;
    for (NSString *key in [[_story passages] allKeys]) {
        Passage *passage = [[_story passages] valueForKey:key];
        PassageView *pv = [self addNewPassageView:passage];
        if ([[_story startPassage] isEqualToString:[passage name]]) {
            [pv setStartPassage:YES];
        }
        if ([pv pos].x < 0 || [pv pos].y < 0) {
            [self findSpaceFor:pv];
        }
        if ([pv bottomRightCorner].x > largestX) {
            largestX = [pv bottomRightCorner].x;
        }
        if ([pv bottomRightCorner].y > largestY) {
            largestY = [pv bottomRightCorner].y;
        }
    }
    
    [_storyView setFrame:CGRectMake(0, 0, largestX, largestY)];
    
    [self updatePassageLinks];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    HIDE_WAIT();
    CGFloat w = MAX(CGRectGetWidth([_storyView frame]), CGRectGetWidth([_scrollView frame]));
    CGFloat h = MAX(CGRectGetHeight([_storyView frame]), CGRectGetHeight([_scrollView frame]));
    [_storyView setFrame:CGRectMake(0.0, 0.0, w, h)];
    [_scrollView setContentSize:[_storyView frame].size];
    [_storyView setNeedsDisplay];
    if (_showSettings) {
        _showSettings = NO;
        [self editStorySettings:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self setTitle:[_story name]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setTitle:@""];
}

- (void)willMoveToParentViewController:(nullable UIViewController *)parent {
    if (!parent) {
        [self handleCloseStory];
    }
}

#pragma mark Autosave
- (void)autosave {
    [super autosave];
    [_story
     save:^(Story *story) {
         
     }
     error:^(NSError *error) {
         AlertError([NSString stringWithFormat:_LS(@"Unable to save the story.\n%@"),
                     [error localizedDescription]],
                    self);
     }];
}

- (NSTimeInterval)autosaveInterval {
    return kYarnDefaultAutosaveInterval;
}

- (void)saveData {
    if (_passageEditorViewController) {
        [_passageEditorViewController saveData];
    }
    else {
        [super saveData];
    }
}

#pragma mark Handlers
- (void)handleExportProofingCopy:(BOOL)createArchive {
    [self publishProofing:YES export:YES createArchive:createArchive];
}

- (void)handleExportStory:(BOOL)createArchive {
    [_story
     saveAndCreateZip:createArchive
     completion:^(Story *story, NSString *zipPath) {
         NSString *path = createArchive ? zipPath:[self createHtmlLinkForExport:story filename:@"story.html"];
         NSURL *url = [NSURL fileURLWithPath:path];
         NSLog(@"Exporting %@", url);
         _exportInteractionController =
         [UIDocumentInteractionController interactionControllerWithURL:url];
         [_exportInteractionController
          presentOpenInMenuFromBarButtonItem:[[self navigationItem] rightBarButtonItem]
          animated:YES];
     }
     error:^(NSError *error) {
         AlertError([NSString stringWithFormat:_LS(@"Unable to archive the story.\n%@"),
                     [error localizedDescription]],
                    self);
         [[self navigationController] popViewControllerAnimated:YES];
         
     }];
}

- (void)handleCloseStory {
    [self invalidateAutosaveTimer];
    [_story
     save:^(Story *story) {
         [[self navigationController] popViewControllerAnimated:YES];
         if (_completionHandler) {
             _completionHandler(_story);
         }
     }
     error:^(NSError *error) {
         AlertError([NSString stringWithFormat:_LS(@"Unable to save the story.\n%@"),
                     [error localizedDescription]],
                    self);
         [[self navigationController] popViewControllerAnimated:YES];
     }];
    _passageEditorViewController = nil;
}

- (void)handleCreateNewPassage {
    if (!_createPassageController) {
        _createPassageController =
        [UIAlertController alertControllerWithTitle:_LS(@"New Passage")
                                            message:_LS(@"Enter name of passage to create.")
                                     preferredStyle:UIAlertControllerStyleAlert];
        [_createPassageController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            
        }];
        [_createPassageController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
        [_createPassageController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Create")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    UITextField *textField = [[_createPassageController textFields] firstObject];
                                    NSString *name = TRIM([textField text]);
                                    if ([[_passageViews allKeys] containsObject:name]) {
                                        AlertError([NSString stringWithFormat:_LS(@"A passage named \"%@\" already exists."), name],
                                                   self);
                                    }
                                    else if ([name notEmpty]) {
                                        Passage *passage = [Passage passageInStory:_story named:name];
                                        PassageView *passageView = [self addNewPassageView:passage];
                                        [self positionPassageView:passageView];
                                        [self handleEditPassageIn:passageView];
                                    }
                                    else {
                                        AlertError(@"You need to provide the passage with a name.",
                                                   self);
                                    }
                                }]];
    }
    UITextField *textField = [[_createPassageController textFields] firstObject];
    [textField setText:@""];
    [self presentViewController:_createPassageController
                       animated:YES
                     completion:^{
                         NSString *title = _LS(@"Untitled Passage");
                         [textField setMarkedText:title
                                    selectedRange:NSMakeRange(0, [title length])];
                     }];
}

- (void)handleDeletePassageIn:(PassageView *)passageView {
    AlertQuestion(_LS(@"Delete Passage"),
                  _LS(@"This action is permanent and cannot be undone.\nAre you sure?"),
                  _LS(@"Cancel"),
                  _LS(@"Delete"),
                  YES,
                  ^(UIAlertAction *action) {
                      [_story deletePassage:[passageView passage]];
                      [passageView removeFromSuperview];
                      [_passageViews removeObjectForKey:[[passageView passage] name]];
                      NSInteger brokenLinks = [self updatePassageLinks];
                      [_storyView setNeedsDisplay];
                      if (brokenLinks) {
                          AlertAndDismissInfo(_LS(@"Warning"),
                                              [NSString stringWithFormat:_LS(@"Detected %d broken links"),
                                               (int)brokenLinks],
                                              1.5,
                                              self);
                      }
                      [self startAutosaveTimer];
                  },
                  self);
}

- (void)handleEditPassageIn:(PassageView *)passageView {
    [self invalidateAutosaveTimer];
    _passageEditorViewController =
    [[PassageEditorViewController alloc] initWithPassageView:passageView
                                                    delegate:self];
    [[self navigationController] pushViewController:_passageEditorViewController
                                           animated:YES];
}

- (void)handleExportArchive {
    if (!_exportArchiveMenuController) {
        _exportArchiveMenuController =
        [UIAlertController alertControllerWithTitle:_LS(@"Export Archive")
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        [_exportArchiveMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Proofing Copy")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleExportProofingCopy:YES];
                                }]];
        
        [_exportArchiveMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Published Story")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handlePublish:YES];
                                }]];
        
        [_exportArchiveMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Story")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleExportStory:YES];
                                }]];
        
        [_exportArchiveMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
    }
    
    //iPad
    UIPopoverPresentationController *presentationController =
    [_exportArchiveMenuController popoverPresentationController];
    [presentationController setBarButtonItem:[[self navigationItem] rightBarButtonItem]];
    [presentationController setPermittedArrowDirections:UIPopoverArrowDirectionAny];
    
    [self presentViewController:_exportArchiveMenuController
                       animated:YES
                     completion:nil];
}

- (void)handleExportHtml {
    if (!_exportHtmlMenuController) {
        _exportHtmlMenuController =
        [UIAlertController alertControllerWithTitle:_LS(@"Export HTML")
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        [_exportHtmlMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Proofing Copy")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleExportProofingCopy:NO];
                                }]];
        
        [_exportHtmlMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Published Story")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handlePublish:NO];
                                }]];
        
        [_exportHtmlMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Story")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleExportStory:NO];
                                }]];
        
        [_exportHtmlMenuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
    }
    
    //iPad
    UIPopoverPresentationController *presentationController =
    [_exportHtmlMenuController popoverPresentationController];
    [presentationController setBarButtonItem:[[self navigationItem] rightBarButtonItem]];
    [presentationController setPermittedArrowDirections:UIPopoverArrowDirectionAny];
    
    [self presentViewController:_exportHtmlMenuController
                       animated:YES
                     completion:nil];
}

- (void)handleMenu {
    if (!_menuController) {
        _menuController =
        [UIAlertController alertControllerWithTitle:nil
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Close Story")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleCloseStory];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Settings")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self editStorySettings:NO];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Toggle Snap to Grid")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleToggleSnapToGrid];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"View Proofing Copy")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleViewProofingCopy];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Play")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleTestPlay];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Export Archive")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleExportArchive];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Export HTML")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleExportHtml];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
    }
    
    //iPad
    UIPopoverPresentationController *presentationController =
    [_menuController popoverPresentationController];
    [presentationController setBarButtonItem:[[self navigationItem] rightBarButtonItem]];
    [presentationController setPermittedArrowDirections:UIPopoverArrowDirectionAny];
    
    [self presentViewController:_menuController
                       animated:YES
                     completion:nil];
}

- (void)handlePlayFromPassageIn:(PassageView *)passageView {
    [self testPlayFrom:[[passageView passage] Id]];
}

- (void)handlePublish:(BOOL)createArchive {
    [self publishProofing:NO export:YES createArchive:createArchive];
}

- (void)handleSetStartPassageIn:(PassageView *)passageView {
    if ([[_story startPassage] notEmpty]) {
        PassageView *pv = [_passageViews valueForKey:[_story startPassage]];
        NSAssert(pv != nil, @"A PassageView instance should exist with a key equal to Story.startPassage");
        [pv setStartPassage:NO];
    }
    [passageView setStartPassage:YES];
    [_story setStartPassage:[[passageView passage] name]];
}

- (void)handleTestPlay {
    [self testPlayFrom:-1];
}

- (void)handleTitleTapped {
    [self editStorySettings:NO];
}

- (void)handleToggleSnapToGrid {
    [self setSnapsToGrid:!_snapsToGrid];
    [_snapToGridLabel setText:[@"Snap To Grid: " stringByAppendingString:_snapsToGrid ? @"On":@"Off"]];
    AlertAndDismissInfo(_snapsToGrid ? _LS(@"Snap to Grid: On"):
                        _LS(@"Snap to Grid: Off"),
                        nil,
                        1.5,
                        self);
}

- (void)handleViewProofingCopy {
    [self publishProofing:YES export:NO createArchive:NO];
}

- (void)editStorySettings:(BOOL)newStory {
    StorySettingsViewController *storySettingsViewController =
    [[StorySettingsViewController alloc] initWithStoryViewController:self];
    [[self navigationController] pushViewController:storySettingsViewController
                                           animated:YES];
}

- (void)publishProofing:(BOOL)proofing
                 export:(BOOL)export
          createArchive:(BOOL)createArchive {
    if (proofing) {
        NSAssert(_proofingFormat != nil, @"Proofing format must have been set already.");
    }
    NSArray *formats = proofing ? _proofingFormats:_formats;
    if (![formats count] ||
        (proofing && !_proofingFormat)) {
        if (!proofing) {
            AlertError(_LS(@"No proofing formats found."),
                       self);
        }
        else {
            AlertError(_LS(@"No story formats found."),
                       self);
        }
    }
    else {
        StoryFormat *format = proofing ? _proofingFormat:nil;
        for (StoryFormat *format_ in formats) {
            if ([[format_ name] isEqualToString:[_story storyFormat]]) {
                format = format_;
                break;
            }
        }
        if (format) {
            SHOW_WAIT();
            [format
             publishStory:_story
             startId:-1
             options:@[]
             createZip:export && createArchive
             completion:^(Story *story, NSString *path) {
                 HIDE_WAIT();
                 if (export) {
                     NSURL *url = [NSURL fileURLWithPath:createArchive ? path:
                                   [self createHtmlLinkForExport:story filename:[path lastPathComponent]]];
                     NSLog(@"Exporting %@", url);
                     _exportInteractionController =
                     [UIDocumentInteractionController interactionControllerWithURL:url];
                     [_exportInteractionController
                      presentOpenInMenuFromBarButtonItem:[[self navigationItem] rightBarButtonItem]
                      animated:YES];
                 }
                 else {
                     WebViewController *webViewController =
                     [[WebViewController alloc] initWithPath:path];
                     [webViewController setTitle:[_story name]];
                     [[self navigationController] pushViewController:webViewController
                                                            animated:YES];
                 }
             }
             error:^(NSError *error) {
                 HIDE_WAIT();
                 AlertError([NSString stringWithFormat:_LS(@"Unable to publish story.\n%@"),
                             [error localizedDescription]],
                            self);
             }];
        }
        else {
            AlertError([_LS(@"Missing story format:") stringByAppendingFormat:@" %@",
                        [_story storyFormat]],
                       self);
        }
    }
}

- (NSString *)createHtmlLinkForExport:(Story *)story filename:(NSString *)filename {
    NSString *path = [[story name] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    path = [path stringByAppendingString:@"-"];
    path = [path stringByAppendingString:[story ifId]];
    path = [path stringByAppendingPathExtension:@"export"];
    path = [path stringByAppendingFormat:@".%@", filename];
    path = [[story path] stringByAppendingPathComponent:path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([filename isEqualToString:@"story.html"]) {
        [fileManager linkItemAtPath:[[story path] stringByAppendingPathComponent:filename]
                             toPath:path
                              error:&error];
    }
    else {
        [fileManager linkItemAtPath:[[[story path] stringByAppendingPathComponent:@"build"]
                                     stringByAppendingPathComponent:filename]
                             toPath:path
                              error:&error];
    }
    if (error) {
        NSLog(@"%@", error);
        path = [[story path] stringByAppendingPathComponent:filename];
    }
    
    return path;
}

#pragma mark Passages
- (PassageView *)addNewPassageView:(Passage *)passage {
    PassageView *pv = [[PassageView alloc] initWith:passage delegate:self];
    [_passageViews setObject:pv forKey:[[pv passage] name]];
    [_storyView addSubview:pv];
    return pv;
}

- (void)adjustScrollContentSize:(PassageView *)passageView {
    if (!CGRectContainsRect([_storyView frame], [passageView frame])) {
        
        CGFloat xInc = 0.0, xOffset = 0.0, yInc = 0.0, yOffset = 0.0;
        CGRect oldFrame = [_storyView frame];
        
        if (CGRectGetMinX(oldFrame) > [passageView topLeftCorner].x) {
            xInc = CGRectGetMinX(oldFrame) - [passageView topLeftCorner].x;
            xOffset = xInc;
        }
        else if (CGRectGetMaxX(oldFrame) < [passageView bottomRightCorner].x) {
            xInc = [passageView bottomRightCorner].x - CGRectGetMaxX(oldFrame);
        }
        
        if (CGRectGetMinY(oldFrame) > [passageView topLeftCorner].y) {
            yInc = CGRectGetMinY(oldFrame) - [passageView topLeftCorner].y;
            yOffset = yInc;
        }
        else if (CGRectGetMaxY(oldFrame) < [passageView bottomRightCorner].y) {
            yInc = [passageView bottomRightCorner].y - CGRectGetMaxY(oldFrame);
        }
        
        [_storyView setFrame:CGRectMake(oldFrame.origin.x, oldFrame.origin.y,
                                        oldFrame.size.width + xInc, oldFrame.size.height + yInc)];
        
        for (PassageView *pv in [_passageViews allValues]) {
            [pv setPos:CGPointMake([pv pos].x + xOffset, [pv pos].y + yOffset)];
        }
        
        [_scrollView setContentSize:[_storyView frame].size];
    }
}

- (void)findSpaceFor:(PassageView *)passageView {
    CGFloat turns = 0.0;
    NSInteger moves = 1;
    CGFloat gridDivision = _snapsToGrid ? 1.0:0.2;
    
    CGFloat pos[2] = {[passageView pos].x, [passageView pos].y};
    while ((pos[0] < 0.0 ||
            pos[1] < 0.0 ||
            [self passageViewCollides:passageView]) &&
           turns < 99.0*gridDivision) {
        pos[(int)floor(fmod(turns*2, 2))] += GridSpacing * gridDivision * floor(copysign(1, fmod(turns, 2) - 1));
        moves -= 1;
        if (moves <= 0) {
            turns += 0.5;
            moves = (int)(ceil(turns)/gridDivision);
        }
        [passageView setPos:CGPointMake(pos[0], pos[1])];
    }
}

- (PassageView *)getPassageViewWithName:(NSString *)name {
    return [_passageViews valueForKey:name];
}

- (PassageView *)getPassageViewWithId:(NSInteger)Id {
    for (PassageView *pv in [_passageViews allValues]) {
        if ([[pv passage] Id] == Id) {
            return pv;
        }
    }
    
    return nil;
}

- (void)testPlayFrom:(NSInteger)startId {
    if (!_formats.count) {
        AlertError(_LS(@"No story formats found."),
                   self);
    }
    else {
        for (StoryFormat *format in _formats) {
            if ([[format name] isEqualToString:[_story storyFormat]]) {
                SHOW_WAIT();
                [format
                 publishStory:_story
                 startId:startId
                 options:@[]
                 createZip:NO
                 completion:^(Story *story, NSString *path) {
                     HIDE_WAIT();
                     WebViewController *webViewController =
                     [[WebViewController alloc] initWithPath:path];
                     [webViewController setTitle:[_story name]];
                     [[self navigationController] pushViewController:webViewController
                                                            animated:YES];
                 }
                 error:^(NSError *error) {
                     HIDE_WAIT();
                     AlertError([NSString stringWithFormat:_LS(@"Unable to publish story.\n%@"),
                                 [error localizedDescription]],
                                self);
                 }];
                return;
            }
        }
        AlertError([_LS(@"Missing story format:") stringByAppendingFormat:@" %@",
                    [_story storyFormat]],
                   self);
    }
}

- (NSInteger)updatePassageLinks {
    NSInteger brokenLinks = 0;
    for (PassageView *pv in [_passageViews allValues]) {
        NSArray *links = [[pv passage] links:YES];
        NSMutableArray *idArray = [NSMutableArray arrayWithCapacity:[links count]];
        BOOL hasBrokenLink = NO;
        for (NSString *link in links) {
            PassageView *lpv = [_passageViews valueForKey:link];
            if (lpv) {
                [idArray addObject:[NSNumber numberWithInteger:[[lpv passage] Id]]];
            }
            else {
                ++brokenLinks;
                hasBrokenLink = YES;
            }
        }
        [pv setLinkedIds:idArray];
        [[pv titleLabel] setBackgroundColor:hasBrokenLink ? [UIColor redColor]:[UIColor magentaColor]];
    }
    
    NSLog(@"%d broken links.", (int)brokenLinks);
    
    return brokenLinks;
}

#pragma mark PassageEditorViewController
- (MediaPickerViewController *)mediaPickerViewControllerForEditor:(PassageEditorViewController *)controller {
    return _mediaPickerViewController;
}

- (void)passageEditorViewController:(PassageEditorViewController *)controller
                          didFinish:(PassageView *)passageView {
    SHOW_WAIT();
    
    if (passageView) {
        for (NSString *link in [[passageView passage] links:YES]) {
            if (![_story getPassageWithName:link]) {
                NSError *error = nil;
                Passage *passage = [_story createNewPassage:link error:&error];
                if (!error) {
                    PassageView *newPassageView = [self addNewPassageView:passage];
                    [newPassageView setPos:[passageView pos]];
                    [self findSpaceFor:newPassageView];
                }
                else {
                    AlertInfo(_LS(@"Error"),
                              [error localizedDescription],
                              _LS(@"Close"),
                              self);
                }
            }
        }
        
        [passageView update];
    }
    
    [_story
     saveToPath:nil
     completion:^(Story *story) {
         HIDE_WAIT();
    }
    error:^(NSError *error) {
        HIDE_WAIT();
    }];
    
    NSInteger brokenLinks = [self updatePassageLinks];
    [[self view] setNeedsDisplay];
    if (brokenLinks) {
        AlertAndDismissInfo(_LS(@"Warning"),
                            [NSString stringWithFormat:_LS(@"Detected %d broken links"),
                             (int)brokenLinks],
                            1.5,
                            self);
    }
}

- (void)passageEditorViewController:(PassageEditorViewController *)controller
            passageNameDidChangeFor:(PassageView *)passageView {
    [_passageViews setObject:passageView forKey:[controller name]];
    [_passageViews removeObjectForKey:[[passageView passage] name]];
    [_story changePassageName:[passageView passage] newName:[controller name]];
}

- (void)passageEditorViewController:(PassageEditorViewController *)controller
                   requestsToDelete:(PassageView *)passageView {
    [_story deletePassage:[passageView passage]];
    [passageView removeFromSuperview];
    [_passageViews removeObjectForKey:[[passageView passage] name]];
}

- (void)passageEditorViewController:(PassageEditorViewController *)controller
                     requestsToSave:(PassageView *)passageView {
    [_story
     save:^(Story *story) {
         
     }
     error:^(NSError *error) {
         
     }];
}

#pragma mark PassageViewDelegate
- (BOOL)passageViewCollides:(PassageView *)passageView {
    NSAssert(passageView != nil, @"PassageView instance should not be nil.");
    
    // Expand the frames by PassageView.Allowance on each side.
    CGRect frame = CGRectInset([passageView frame], -[PassageView allowance], -[PassageView allowance]);
    for (PassageView *pv in [_passageViews allValues]) {
        if (![passageView isEqual:pv]) {
            if (CGRectIntersectsRect(frame, CGRectInset([pv frame], -[PassageView allowance], -[PassageView allowance]))) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)positionPassageView:(PassageView *)passageView {
    NSAssert(passageView != nil, @"PassageView instance should not be nil.");
    
    for (PassageView *pv in [_passageViews allValues]) {
        if (![passageView isEqual:pv]) {
            [pv displace:passageView];
        }
    }
    
    if (_snapsToGrid) {
        CGFloat xMove = 0.0, yMove = 0.0;
        CGFloat hGrid = ([PassageView dimension] + [PassageView allowance]) / 2.0;
        CGFloat vGrid = hGrid;
        
        CGFloat leftMove = fmod([passageView pos].x, hGrid);
        
        if (leftMove < hGrid / 2) {
            xMove = - leftMove;
        }
        else {
            xMove = hGrid - leftMove;
        }
        
        CGFloat upMove = fmod([passageView pos].y, vGrid);
        
        if (upMove < vGrid / 2) {
            yMove = - upMove;
        }
        else {
            yMove = vGrid - upMove;
        }
        
        passageView.pos = CGPointMake([passageView pos].x + xMove, [passageView pos].y + yMove);
    }
    
    [self adjustScrollContentSize:passageView];
    [_storyView setNeedsDisplay];
    [_scrollView scrollRectToVisible:[passageView frame] animated:YES];
    [self startAutosaveTimer];
}

- (void)showPassageViewMenu:(PassageView *)passageView {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Delete")
                              style:UIAlertActionStyleDestructive
                            handler:^(UIAlertAction * __nonnull action) {
                                [self handleDeletePassageIn:passageView];
                            }]];
    
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Edit")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * __nonnull action) {
                                [self handleEditPassageIn:passageView];
                            }]];
    
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Set as Start")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * __nonnull action) {
                                [self handleSetStartPassageIn:passageView];
                            }]];
    
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Play from this Passage")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * __nonnull action) {
                                [self handlePlayFromPassageIn:passageView];
                            }]];
    
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Cancel")
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    
    // iPad
    UIPopoverPresentationController *presenter =
    [alertController popoverPresentationController];
    [presenter setSourceView:[passageView menuButton]];
    [presenter setPermittedArrowDirections:UIPopoverArrowDirectionAny];
    
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

#pragma mark UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
      shouldReceiveTouch:(UITouch *)touch {
    return ([[self navigationController] visibleViewController] == self &&
            (ABS([touch locationInView:[[self navigationController] navigationBar]].x -
                 CGRectGetWidth([[self navigationController] navigationBar].frame) / 2.0) < 50));
}

#pragma mark UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _storyView;
}

@end
