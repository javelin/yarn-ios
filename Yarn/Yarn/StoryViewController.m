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

@property (nonatomic, strong) UIAlertController *createPassageController;
@property (nonatomic, strong) UIAlertController *menuController;

@property (nonatomic, strong) UIDocumentInteractionController *exportInteractionController;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) MediaPickerViewController *mediaPickerViewController;

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
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTitleTapped)];
        
        [[self navigationItem] setLeftBarButtonItem:
         [[UIBarButtonItem alloc] initWithTitle:@"Menu"
                                          style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector(handleMenu)]];
        
        UIBarButtonItem* play =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                      target:self
                                                      action:@selector(handleTestPlay)];
        
        UIBarButtonItem* add =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(handleCreateNewPassage)];
        
        if (IS_IPAD()) {
            UIBarButtonItem* close =
            [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close"]
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(handleCloseStory)];
            [[self navigationItem] setRightBarButtonItems:@[close, play, add]];
        }
        else {
            [[self navigationItem] setRightBarButtonItems:@[play, add]];
        }
        
        _mediaPickerViewController =
        [[MediaPickerViewController alloc] initWithIFId:[_story ifId]];
    }
    
    return self;
}

- (void)createViews {
    [self setView:[UIView new]];
    
    _storyView = [[StoryView alloc] initWithController:self];
    _scrollView = [[UIScrollView alloc] init];
    [_scrollView setBackgroundColor:[UIColor lightGrayColor]];
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
    
    CGFloat largestX = 0, largestY = 0;
    for (NSString *key in [[_story passages] allKeys]) {
        Passage *passage = [[_story passages] valueForKey:key];
        PassageView *pv = [self addNewPassageView:passage];
        if ([[_story startPassage] isEqualToString:[passage name]]) {
            [pv setStartPassage:YES];
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
    [[[self navigationController] navigationBar] addGestureRecognizer:_tapGestureRecognizer];
    [self setTitle:[_story name]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[[self navigationController] navigationBar] removeGestureRecognizer:_tapGestureRecognizer];
    [self setTitle:@""];
}

#pragma mark Handlers
- (void)handleArchiveProofingCopy {
    AlertAndDismissInfo(_LS(@"Archive Proofing Copy"),
                        _LS(@"Coming soon."),
                        1.0,
                        self);
}

- (void)handleArchiveStory {
    AlertAndDismissInfo(_LS(@"Archive Story"),
                        _LS(@"Coming soon."),
                        1.0,
                        self);
}

- (void)handleCloseStory {
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
                      [self updatePassageLinks];
                  },
                  self);
}

- (void)handleEditPassageIn:(PassageView *)passageView {
    PassageEditorViewController *passageEditorViewController =
    [[PassageEditorViewController alloc] initWithPassageView:passageView
                                                    delegate:self];
    [[self navigationController] pushViewController:passageEditorViewController
                                           animated:YES];
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
         [UIAlertAction actionWithTitle:_LS(@"Archive Proofing Copy")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleArchiveProofingCopy];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Play")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleTestPlay];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Publish Story")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handlePublish];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Archive Story")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleArchiveStory];
                                }]];
        
        [_menuController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
    }
    
    //iPad
    UIPopoverPresentationController *presentationController =
    [_menuController popoverPresentationController];
    [presentationController setBarButtonItem:[[self navigationItem] leftBarButtonItem]];
    [presentationController setPermittedArrowDirections:UIPopoverArrowDirectionAny];
    [self presentViewController:_menuController
                       animated:YES
                     completion:nil];
}

- (void)handlePlayFromPassageIn:(PassageView *)passageView {
    [self testPlayFrom:[[passageView passage] Id]];
}

- (void)handlePublish {
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
                 startId:-1
                 options:@[]
                 createZip:YES
                 completion:^(Story *story, NSString *path) {
                     HIDE_WAIT();
                     if ([[path pathExtension] isEqualToString:@"zip"]) {
                         NSURL *url = [NSURL URLWithString:[@"file://" stringByAppendingString:path]];
                         NSLog(@"Exporting %@", url);
                         _exportInteractionController =
                         [UIDocumentInteractionController interactionControllerWithURL:url];
                         [_exportInteractionController
                          presentOpenInMenuFromBarButtonItem:[[self navigationItem] leftBarButtonItem]
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
                return;
            }
        }
        AlertError([_LS(@"Missing story format:") stringByAppendingFormat:@" %@",
                    [_story storyFormat]],
                   self);
    }
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
    AlertAndDismissInfo(_snapsToGrid ? _LS(@"Snap to Grid: Yes"):
                        _LS(@"Snap to Grid: No"),
                        nil,
                        1.5,
                        self);
}

- (void)handleViewProofingCopy {
    if (!_proofingFormat && ![_proofingFormats count]) {
        AlertError(_LS(@"No proofing formats found."), self);
    }
    else {
        NSAssert(self.proofingFormat != nil, @"Proofing format must have been set already.");
        SHOW_WAIT();
        [_proofingFormat
         publishStory:_story
         startId:-1
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
    }
}

- (void)editStorySettings:(BOOL)newStory {
    StorySettingsViewController *storySettingsViewController =
    [[StorySettingsViewController alloc] initWithStoryViewController:self];
    [[self navigationController] pushViewController:storySettingsViewController
                                           animated:YES];
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
        
    }
    error:^(NSError *error) {
        
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
    [self.storyView setNeedsDisplay];
    [self.scrollView scrollRectToVisible:[passageView frame] animated:YES];
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
