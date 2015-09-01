//
//  StoriesViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/12/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "SSZipArchive.h"
#import "StoriesViewController.h"
#import "Story.h"
#import "StoryViewController.h"
#import "ViewUtils.h"

typedef enum StorySortMethod {
    StorySortMethodAlpha,
    StorySortMethodLatest
} StorySortMethod;

@interface StoriesViewController () {
    BOOL _shouldReload;
    StorySortMethod _sortMethod;
}

@property (nonatomic, strong) NSMutableArray *stories;
@property (nonatomic, strong) StoryViewController *storyViewController;

@end

@implementation StoriesViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _stories = [NSMutableArray array];
        _shouldReload = YES;
        _sortMethod = StorySortMethodLatest;
        [self setTitle:_LS(@"Stories")];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate]
         setDelegate:self];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self shouldReload]) {
        SHOW_WAIT();
        DISPATCH_ASYNC(^{
            [_stories removeAllObjects];
            
            NSFileManager* manager = [NSFileManager defaultManager];
            
            __weak NSString *saveDir = [self saveDir];
            NSError *error = nil;
            if (![manager fileExistsAtPath:saveDir]) {
                [manager createDirectoryAtPath:[[self class] saveDir]
                   withIntermediateDirectories:NO
                                    attributes:nil
                                         error:&error];
                if (error) {
                    NSLog(@"%@", error);
                }
            }
            
            NSArray *contents = [manager contentsOfDirectoryAtPath:saveDir error:&error];
            if (error) {
                NSLog(@"%@", error);
            }
            else {
                for (NSInteger i = 0; i < contents.count; ++i) {
                    NSString *path = [saveDir stringByAppendingPathComponent:[contents objectAtIndex:i]];
                    NSLog(@"File %d: %@", (int)(i + 1), path);
                    error = nil;
                    Story* story = [Story loadInfo:path error:&error];
                    if (error) {
                        NSLog(@"%@", error);
                    }
                    else if (story) {
                        [_stories addObject:story];
                    }
                }
            }
            
            [self sortObjects];
            _shouldReload = NO;
            
            DISPATCH_ASYNC_MAIN(^{
                HIDE_WAIT();
                [[self tableView] reloadData];
            });
        });
    }
}

#pragma mark AppDataDelegate

- (BOOL)importData:(NSURL *)url {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    void (^removeUrl)() = ^{
        NSError *error = nil;
        [fileManager removeItemAtURL:url error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    };
    if ([[[self navigationController] visibleViewController]
         isKindOfClass:[UIAlertController class]]) {
        // We hate it if there's an alert controller being displayed.
        removeUrl();
        return NO;
    }
    else if (_storyViewController) {
        AlertError(_LS(@"Unable to import when editing a story."), self);
        removeUrl();
        return NO;
    }
    else {
        SHOW_WAIT();
        DispatchAsync(^{
            NSString *importPath = [AppDirectory() stringByAppendingPathComponent:@"Import"];
            BOOL isDir, exists = [fileManager fileExistsAtPath:importPath isDirectory:&isDir];
            NSError *error = nil;
            if (exists) {
                if (!isDir) {
                    [fileManager removeItemAtPath:importPath error:&error];
                    if (error) {
                        NSLog(@"%@", error);
                    }
                    exists = NO;
                }
            }
            if (!exists) {
                error = nil;
                [fileManager createDirectoryAtPath:importPath
                       withIntermediateDirectories:NO
                                        attributes:nil
                                             error:&error];
                if (error) {
                    NSLog(@"%@", error);
                    removeUrl();
                    DispatchAsyncMain(^{
                        HIDE_WAIT();
                        AlertError(@"Unable to create temporary directory.",
                                   self);
                    });
                }
            }
            NSString *tempPath = [importPath stringByAppendingPathComponent:[[NSUUID new] UUIDString]];
            error = nil;
            NSLog(@"Creating temporary directory %@", tempPath);
            [fileManager createDirectoryAtPath:tempPath
                   withIntermediateDirectories:NO
                                    attributes:nil
                                         error:&error];
            if (error) {
                NSLog(@"%@", error);
                removeUrl();
                DispatchAsyncMain(^{
                    HIDE_WAIT();
                    AlertError(@"Unable to create temporary directory.",
                               self);
                });
            }
            
            void (^removeTempFiles)() = ^() {
                NSError *error = nil;
                removeUrl();
                [fileManager removeItemAtPath:tempPath error:&error];
                if (error) {
                    NSLog(@"%@", error);
                }
            };
            
            [SSZipArchive unzipFileAtPath:[url path]
                            toDestination:tempPath
                                overwrite:YES
                                 password:nil
                                    error:&error];
            if (error) {
                NSLog(@"%@", error);
                removeTempFiles();
                DispatchAsyncMain(^{
                    HIDE_WAIT();
                    AlertError(@"Unable to extract archive contents.",
                               self);
                });
            }
            else {
                error = nil;
                
                NSString *htmlPath = [tempPath stringByAppendingPathComponent:@"story.html"];
                if (![fileManager fileExistsAtPath:htmlPath]) {
                    htmlPath = [tempPath stringByAppendingPathComponent:@"game.html"];
                    if (![fileManager fileExistsAtPath:htmlPath]) {
                        htmlPath = [tempPath stringByAppendingPathComponent:@"proof.html"];
                        if (![fileManager fileExistsAtPath:htmlPath]) {
                            // Nada!
                            removeTempFiles();
                            DispatchAsyncMain(^{
                                HIDE_WAIT();
                                AlertError(@"Missing story.html file.",
                                           self);
                            });
                            return;
                        }
                    }
                    [fileManager moveItemAtPath:htmlPath
                                         toPath:[tempPath stringByAppendingPathComponent:@"story.html"]
                                          error:&error];
                    if (error) {
                        NSLog(@"%@", error);
                        removeTempFiles();
                        DispatchAsyncMain(^{
                            HIDE_WAIT();
                            AlertError(@"Missing or corrupt story.html file.",
                                       self);
                        });
                        return;
                    }
                }
                
                Story* story = [Story new];
                [story setPath:tempPath];
                [story
                 load:^(Story *story) {
                     void (^writeToSaveDir)(Story *_oldStory) = ^(Story *_oldStory){
                         NSString *savePath = [[self saveDir] stringByAppendingPathComponent:[story ifId]];
                         NSString *imagesPath = [savePath stringByAppendingPathComponent:@"images"];
                         
                         NSError *error = nil;
                         if ([fileManager fileExistsAtPath:savePath]) {
                             [fileManager removeItemAtPath:savePath error:&error];
                             if (error) {
                                 NSLog(@"%@", error);
                                 removeTempFiles();
                                 DispatchAsyncMain(^{
                                     HIDE_WAIT();
                                     AlertError(_LS(@"Unable to import archive. Failed to overwrite old save directory."),
                                                self);
                                 });
                                 return;
                             }
                         }
                         
                         [fileManager createDirectoryAtPath:imagesPath
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&error];
                         if (error) {
                             NSLog(@"%@", error);
                             removeTempFiles();
                             DispatchAsyncMain(^{
                                 HIDE_WAIT();
                                 if (_oldStory) {
                                     [_stories removeObject:_oldStory];
                                     [[self tableView] reloadData];
                                 }
                                 AlertError(_LS(@"Unable to import archive. Failed to create save directory."),
                                            self);
                             });
                             return;
                         }
                         
                         NSString *tempImagesPath = [tempPath stringByAppendingPathComponent:@"images"];
                         NSArray *images = [fileManager contentsOfDirectoryAtPath:tempImagesPath error:&error];
                         int failedTransfers = 0;
                         if (error) {
                             NSLog(@"%@", error);
                         }
                         else {
                             for (NSString *filename in images) {
                                 error = nil;
                                 [fileManager moveItemAtPath:[tempImagesPath stringByAppendingPathComponent:filename]
                                                      toPath:[imagesPath stringByAppendingPathComponent:filename]
                                                       error:&error];
                                 if (error) {
                                     NSLog(@"%@", error);
                                     failedTransfers++;
                                 }
                             }
                         }
                         
                         [story setPath:savePath];
                         [story setLastUpdate:[NSDate date]];
                         [story
                          save:^(Story *story) {
                              removeTempFiles();
                              if (_oldStory) {
                                  [_stories removeObject:_oldStory];
                              }
                              [_stories addObject:story];
                              [self sortObjects];
                              DispatchAsyncMain(^{
                                  [[self tableView] reloadData];
                                  HIDE_WAIT();
                                  NSString *msg = failedTransfers ?
                                  [NSString stringWithFormat:_LS(@"Story successfully imported, but failed to transfer %d image files."), failedTransfers]:
                                  _LS(@"Story successfully imported.");
                                  AlertInfo(_LS(@"Import"),
                                            msg,
                                            _LS(@"Close"),
                                            self);
                              });
                          }
                          error:^(NSError *error) {
                              NSLog(@"%@", error);
                              removeTempFiles();
                              DispatchAsyncMain(^{
                                  if (_oldStory) {
                                      [_stories removeObject:_oldStory];
                                      [[self tableView] reloadData];
                                  }
                                  HIDE_WAIT();
                                  AlertError(_LS(@"Unable to import archive. Failed to save story."),
                                             self);
                              });
                              
                          }];
                     };
                     
                     Story *duplicate = nil;
                     for (Story *story_ in _stories) {
                         if ([[story ifId] isEqualToString:[story_ ifId]]) {
                             duplicate = story_;
                             break;
                         }
                     }
                     
                     if (duplicate) {
                         AlertQuestionWithCancelHandler(_LS(@"Duplicate Story"),
                                                        _LS(@"A story with the same IFID exists? Do you want to overwrite the existing story?"),
                                                        _LS(@"Cancel"),
                                                        ^(UIAlertAction *action) {
                                                            HIDE_WAIT();
                                                            AlertInfo(_LS(@"Import"),
                                                                      _LS(@"Import cancelled."),
                                                                      _LS(@"Close"),
                                                                      self);
                                                            removeTempFiles();
                                                        },
                                                        _LS(@"Overwrite"),
                                                        YES,
                                                        ^(UIAlertAction *action) {
                                                            writeToSaveDir(duplicate);
                                                        },
                                                        self);
                     }
                     else {
                         writeToSaveDir(nil);
                     }
                 }
                 error:^(NSError *error) {
                     NSLog(@"%@", error);
                     DispatchAsyncMain(^{
                         HIDE_WAIT();
                         AlertError(_LS(@"Unable to import archive."),
                                    self);
                     });
                     removeTempFiles();
                 }];
            }
        });
    }
    
    return YES;
}

- (void)saveData {
    if (_storyViewController) {
        [_storyViewController saveData];
    }
}

#pragma mark EntityList
- (void)addNewEntity {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:_LS(@"Create Story")
                                        message:_LS(@"Enter title of new story.")
                                 preferredStyle:UIAlertControllerStyleAlert];
    __block UITextField *titleTextField = nil;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * __nonnull textField) {
        [textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [textField setAutocorrectionType:UITextAutocorrectionTypeDefault];
        titleTextField = textField;
    }];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Cancel")
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Create")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * __nonnull action) {
                                NSLog(@"New Story");
                                SHOW_WAIT();
                                NSString *title = TRIM([[[alertController textFields] firstObject] text]);
                                if (![title length]) {
                                    title = _LS(@"Untitled Story");
                                }
                                Story *story = [[Story alloc] initWithDefaults];
                                [story setName:title];
                                NSString *formatName = [[NSUserDefaults standardUserDefaults]
                                                    objectForKey:(NSString *)kYarnKeyDefaultStoryFormat];
                                NSArray *storyFormats = [[HomeViewController sharedInstance] storyFormats];
                                if (![formatName notEmpty]) {
                                    formatName = (NSString *)kYarnDefaultStoryFormat;
                                }
                                for (StoryFormat *storyFormat in storyFormats) {
                                    if ([[storyFormat name] isEqualToString:formatName]) {
                                        [story setStoryFormat:formatName];
                                        formatName = nil;
                                        break;
                                    }
                                }
                                if (formatName) {
                                    [story setStoryFormat:[[storyFormats firstObject] name]];
                                }
                                [story
                                 saveToPath:[self saveDir]
                                 completion:^(Story *story) {
                                     HIDE_WAIT();
                                     [_stories addObject:story];
                                     _storyViewController =
                                     [[StoryViewController alloc] initWithStory:story
                                                                        formats:storyFormats
                                                                proofingFormats:[[HomeViewController sharedInstance] proofingFormats]
                                                                   showSettings:YES
                                                                     completion:^(Story *story) {
                                                                         _storyViewController = nil;
                                                                         [[self tableView] reloadData];
                                                                     }];
                                     [[self navigationController] pushViewController:_storyViewController
                                                                            animated:YES];
                                 }
                                 error:^(NSError *error) {
                                     AlertError([_LS(@"Unable to create story.\n")
                                                 stringByAppendingString:[error localizedDescription]],
                                                self);
                                 }];
                            }]];
    [self presentViewController:alertController
                       animated:YES
                     completion:^{
                         DISPATCH_ASYNC_MAIN(^{
                             NSString *title = _LS(@"Untitled Story");
                             [titleTextField setMarkedText:title
                                             selectedRange:NSMakeRange(0, [title length])];
                         });
                     }];
}

- (BOOL)shouldReload {
    return _shouldReload;
}

- (void)sortObjects {
    [_stories sortUsingComparator:^NSComparisonResult(id  __nonnull obj1, id  __nonnull obj2) {
        Story *s1 = obj1, *s2 = obj2;
        return _sortMethod == StorySortMethodAlpha ?
        [[s1 name] compare:[s2 name]]:[[s2 lastUpdate] compare:[s1 lastUpdate]];
    }];
}

- (NSString *)saveDir {
    static NSString *saveDir;
    if (!saveDir) {
        saveDir = [AppDirectory() stringByAppendingPathComponent:(NSString *)kYarnStorySaveDir];
    }
    return saveDir;
}

#pragma mark Handlers
- (void)handlePlayStory:(Story *)story {
    [story
     load:^(Story *story) {
         for (StoryFormat *format in [[HomeViewController sharedInstance] storyFormats]) {
             if ([[format name] isEqualToString:[story storyFormat]]) {
                 SHOW_WAIT();
                 [format
                  publishStory:story
                  startId:-1
                  options:@[]
                  createZip:NO
                  completion:^(Story *story, NSString *path) {
                      HIDE_WAIT();
                      WebViewController *webViewController =
                      [[WebViewController alloc] initWithPath:path];
                      [webViewController setTitle:[story name]];
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
                     [story storyFormat]],
                    self);
     }
     error:^(NSError *error) {
         AlertError([_LS(@"Unable to load story.\n") stringByAppendingString:[error localizedDescription]],
                    self);
     }];
}

- (void)handleEditStory:(Story *)story {
    [story
     load:^(Story *story) {
         _storyViewController =
         [[StoryViewController alloc] initWithStory:story
                                            formats:[[HomeViewController sharedInstance] storyFormats]
                                    proofingFormats:[[HomeViewController sharedInstance] proofingFormats]
                                       showSettings:NO
                                         completion:^(Story *story) {
                                             _storyViewController = nil;
                                             [[self tableView] reloadData];
                                         }];
         [[self navigationController] pushViewController:_storyViewController animated:YES];
     }
     error:^(NSError *error) {
         AlertError([_LS(@"Unable to load story.\n") stringByAppendingString:[error localizedDescription]],
                    self);
     }];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_stories count] ? [_stories count]:1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseId = @"StoryViewCell";
    static NSString *newReuseId = @"NewStoryViewCell";
    UITableViewCell *cell = nil;
    if (![_stories count]) {
        cell = [tableView dequeueReusableCellWithIdentifier:newReuseId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:newReuseId];
            [[cell textLabel] setTextColor:[UIColor blueColor]];
            [cell prepareForReuse];
        }
        
        [[cell textLabel] setText:_LS(@"+ Create New Story.")];
    }
    else {
        Story *story = [_stories objectAtIndex:[indexPath row]];
        
        cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:reuseId];
            [cell prepareForReuse];
        }
        
        [[cell textLabel] setText:[story name]];
        [[cell detailTextLabel] setText:
         [_LS(@"Updated ") stringByAppendingString:
         [NSDateFormatter localizedStringFromDate:[story lastUpdate]
                                        dateStyle:NSDateFormatterShortStyle
                                        timeStyle:NSDateFormatterShortStyle]]];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return [_stories count] > 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AlertQuestion(_LS(@"Delete Story"),
                      _LS(@"This action is permanent and cannot be undone.\nAre you sure?"),
                      _LS(@"Cancel"),
                      _LS(@"Delete"),
                      YES,
                      ^(UIAlertAction *action) {
                          Story *story = [_stories objectAtIndex:[indexPath row]];
                          [story
                           deleteSaved:^(Story *story_) {
                               [_stories removeObject:story];
                               if ([_stories count]) {
                                   [tableView deleteRowsAtIndexPaths:@[indexPath]
                                                    withRowAnimation:UITableViewRowAnimationFade];
                               }
                               else {
                                   [tableView reloadData];
                               }
                           }
                           error:^(NSError *error) {
                               AlertError([NSString stringWithFormat:_LS(@"Unable to the story.\n%@"),
                                           [error localizedDescription]],
                                          self);
                           }];
                      },
                      self);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if ([_stories count] > 0) {
        Story *story = [_stories objectAtIndex:[indexPath row]];
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:[story name]
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Play")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handlePlayStory:story];
                                }]];
        [alertController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Edit")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self handleEditStory:story];
                                }]];
        [alertController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
        
        UIPopoverPresentationController *popoverController =
        [alertController popoverPresentationController];
        [popoverController setSourceView:[[tableView cellForRowAtIndexPath:indexPath] textLabel]];
        [popoverController setPermittedArrowDirections:UIPopoverArrowDirectionAny];
        
        [[self parentViewController] presentViewController:alertController
                                                  animated:YES
                                                completion:nil];
    }
    else {
        [self addNewEntity];
    }
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0;
}

@end
