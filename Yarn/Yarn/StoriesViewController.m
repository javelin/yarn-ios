//
//  StoriesViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/12/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "Constants.h"
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

@end

@implementation StoriesViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _stories = [NSMutableArray array];
        _shouldReload = YES;
        _sortMethod = StorySortMethodLatest;
        [self setTitle:_LS(@"Stories")];
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
                                     [[self tableView] reloadData];
                                     StoryViewController *storyViewController =
                                     [[StoryViewController alloc] initWithStory:story
                                                                        formats:storyFormats
                                                                proofingFormats:[[HomeViewController sharedInstance] proofingFormats]
                                                                   showSettings:YES];
                                     [[self navigationController] pushViewController:storyViewController
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
        saveDir = [AppDirectory() stringByAppendingPathComponent:@"stories"];
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
         StoryViewController *storyViewController =
         [[StoryViewController alloc] initWithStory:story
                                            formats:[[HomeViewController sharedInstance] storyFormats]
                                    proofingFormats:[[HomeViewController sharedInstance] proofingFormats]
                                       showSettings:NO];
         [[self navigationController] pushViewController:storyViewController animated:YES];
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
