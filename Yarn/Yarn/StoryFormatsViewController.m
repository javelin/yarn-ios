//
//  StoryFormatsViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "InputAccessoryView.h"
#import "StoryFormat.h"
#import "StoryFormatViewController.h"
#import "StoryFormatsViewController.h"
#import "ViewUtils.h"

@interface StoryFormatsViewController () {
    BOOL _proofing;
    BOOL _shouldGatherFormats;
    BOOL _shouldReload;
    NSMutableArray *_storyFormats;
}

@property (nonatomic, strong) NSArray *sections;

@end

@implementation StoryFormatsViewController

- (instancetype)initWithBuiltInFormats:(NSArray *)formats proofing:(BOOL)proofing {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _builtInFormatNames = [NSArray arrayWithArray:formats];
        _proofing = proofing;
        _sections = @[[NSMutableArray array],
                      [NSMutableArray array]];
        _storyFormats = [NSMutableArray array];
        _shouldGatherFormats = YES;
        [self loadBuiltIns];
        [self loadImported];
        _shouldReload = NO;
        [self setTitle:proofing ? _LS(@"Proofing"):_LS(@"Story Formats")];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)storyFormats {
    if (_shouldGatherFormats) {
        [_storyFormats removeAllObjects];
        for (NSArray *formats in _sections) {
            [_storyFormats addObjectsFromArray:formats];
        }
        _shouldGatherFormats = NO;
    }
    
    return _storyFormats;
}

- (void)loadBuiltIns {
    NSMutableArray *builtIns = [_sections firstObject];
    if (![builtIns count]) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        for (NSString *name in _builtInFormatNames) {
            NSURL* url = [mainBundle URLForResource:@"format"
                                      withExtension:@"js"
                                       subdirectory:[@"storyformats" stringByAppendingPathComponent:name]];
            NSURL* imageUrl = [mainBundle URLForResource:@"icon"
                                           withExtension:@"svg"
                                            subdirectory:[@"storyformats" stringByAppendingPathComponent:name]];
            NSLog(@"Story format URL: %@", url);
            StoryFormat *format = [[StoryFormat alloc] initWithName:name url:url imageUrl:imageUrl userAdded:NO];
            [format load:^(StoryFormat *storyFormat) {
                [builtIns addObject:storyFormat];
                [self sortObjects];
                [[self tableView] reloadData];
                _shouldGatherFormats = YES;
            } error:^(NSError *error) {
                AlertError([NSString stringWithFormat:_LS(@"Unable to load the '%@' story format.\n%@"),
                            name,
                            [error localizedDescription]],
                           self);
                NSLog(@"%@", error);
            }];
        }
    }
}

- (void)loadImported {
    NSMutableArray *imported = [_sections lastObject];
    [imported removeAllObjects];
    
    NSFileManager* manager = [NSFileManager defaultManager];
    
    NSString *saveDir = [self saveDir];
    NSError *error = nil;
    if (![manager fileExistsAtPath:saveDir]) {
        [manager createDirectoryAtPath:saveDir
           withIntermediateDirectories:NO
                            attributes:nil
                                 error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    }
    
    error = nil;
    NSArray *contents = [manager contentsOfDirectoryAtPath:saveDir error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    else {
        for (NSInteger i = 0; i < contents.count; ++i) {
            NSString *path = [[saveDir stringByAppendingPathComponent:[contents objectAtIndex:i]]
                              stringByAppendingPathComponent:@"format.js"];
            NSURL *url = [NSURL URLWithString:[@"file://" stringByAppendingString:path]];
            error = nil;
            StoryFormat *format = [[StoryFormat alloc] initWithName:[path lastPathComponent]
                                                                url:url
                                                           imageUrl:nil
                                                          userAdded:YES];
            [format load:^(StoryFormat *storyFormat) {
                _shouldGatherFormats = YES;
                [imported addObject:storyFormat];
                [self sortObjects];
                [[self tableView] reloadData];
            } error:^(NSError *error) {
                AlertError([NSString stringWithFormat:_LS(@"Unable to load the '%@' story format.\n%@"),
                            [path lastPathComponent],
                            [error localizedDescription]],
                           self);
                NSLog(@"%@", error);
            }];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self shouldReload]) {
        SHOW_WAIT();
        [self loadBuiltIns];
        [self loadImported];
            
        _shouldReload = NO;
        
        HIDE_WAIT();
    }
}

#pragma mark EntityList
- (void)addNewEntity {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:_LS(@"Import Story Format")
                                        message:_LS(@"Enter the URL of story format to import:")
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [textField setPlaceholder:@"http://"];
        InputAccessoryView *inputAccessoryView =
        [[InputAccessoryView alloc] initWithHideHandler:nil];
        [textField setInputAccessoryView:inputAccessoryView];
        [inputAccessoryView addButtonWithTitle:@"http://" handler:^(NSString *title) {
            [textField replaceRange:textField.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"https://" handler:^(NSString *title) {
            [textField replaceRange:textField.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"ftp://" handler:^(NSString *title) {
            [textField replaceRange:textField.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"www" handler:^(NSString *title) {
            [textField replaceRange:textField.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"/" handler:^(NSString *title) {
            [textField replaceRange:textField.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"." handler:^(NSString *title) {
            [textField replaceRange:textField.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@".com" handler:^(NSString *title) {
            [textField replaceRange:textField.selectedTextRange withText:title];
        }];
    }];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Cancel")
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    [alertController addAction:
     [UIAlertAction
      actionWithTitle:_LS(@"Import")
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {
                UITextField *textField = [[alertController textFields] firstObject];
                NSString *urlStr = TRIM([textField text]);
                if ([urlStr notEmpty]) {
                    SHOW_WAIT();
                    StoryFormat *format = [[StoryFormat alloc] initWithName:@"Import Format"
                                                                        url:[NSURL URLWithString:urlStr]
                                                                   imageUrl:nil
                                                                  userAdded:YES];
                    [format
                     load:^(StoryFormat *storyFormat) {
                         HIDE_WAIT();
                         if ([format isProofing]) {
                             
                         }
                         else {
                             [[_sections lastObject] addObject:format];
                             [self sortObjects];
                             [[self tableView] reloadData];
                             _shouldGatherFormats = YES;
                         }
                     }
                     error:^(NSError *error) {
                         HIDE_WAIT();
                         AlertError([NSString stringWithFormat:_LS(@"Unable to import fromat from '%@'.\n%@"),
                                     urlStr,
                                     [error localizedDescription]],
                                    self);
                     }];
                }
            }]];
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

- (BOOL)shouldReload {
    return _shouldReload;
}

- (void)sortObjects {
    for (NSMutableArray *formats in _sections) {
        [formats sortUsingComparator:^NSComparisonResult(id  __nonnull obj1, id  __nonnull obj2) {
            StoryFormat *s1 = obj1, *s2 = obj2;
            return [[s1 name] compare:[s2 name]];
        }];
    }
}

- (NSString *)saveDir {
    return _proofing ? [self proofingSaveDir]:[self regularSaveDir];
}

- (NSString *)proofingSaveDir {
    static NSString *saveDir;
    if (!saveDir) {
        saveDir = [AppDirectory() stringByAppendingPathComponent:
                   @"proofing-formats"];
    }
    return saveDir;
}

- (NSString *)regularSaveDir {
    static NSString *saveDir;
    if (!saveDir) {
        saveDir = [AppDirectory() stringByAppendingPathComponent:
                   @"formats"];
    }
    return saveDir;
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [[_sections objectAtIndex:section] count];
    if (section == 1) {
        return count ? count:1;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseId = @"StoryFormatViewCell";
    static NSString *newReuseId = @"NewStoryFormatViewCell";
    UITableViewCell *cell = nil;
    NSArray *formats = [_sections objectAtIndex:[indexPath section]];
    if ([formats count]) {
        StoryFormat *storyFormat = [formats objectAtIndex:[indexPath row]];
        
        cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:reuseId];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            [cell prepareForReuse];
        }
        
        [[cell textLabel] setText:[storyFormat name]];
        [[cell detailTextLabel] setText:SanitizeString([[storyFormat properties] objectForKey:@"author"], YES)];
    }
    else if ([indexPath section] == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:newReuseId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:newReuseId];
            [[cell textLabel] setTextColor:[UIColor blueColor]];
            [cell prepareForReuse];
        }
        
        [[cell textLabel] setText:_LS(@"+ Import Story Format.")];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section ? _LS(@"3rd Party"):_LS(@"Bundled (Twine)");
}

#pragma mark UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [indexPath section] > 0 && [[_sections lastObject] count] > 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:_LS(@"Delete Format")
                                            message:_LS(@"This action is permanent and cannot be undone.\nAre you sure?")
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Cancel")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
        [alertController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Delete")
                                  style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction *action) {
                                    [tableView deleteRowsAtIndexPaths:@[indexPath]
                                                     withRowAnimation:UITableViewRowAnimationFade];
                                }]];
        [[self parentViewController] presentViewController:alertController
                                                  animated:YES
                                                completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSArray *formats = [_sections objectAtIndex:[indexPath section]];
    if ([indexPath section] == 1 && ![formats count]) {
        [self addNewEntity];
    }
    else {
        StoryFormat *format = [formats objectAtIndex:indexPath.row];
        StoryFormatViewController *storyFormatViewContoller =
        [[StoryFormatViewController alloc] initWithStoryFormat:format];
        [[self navigationController] pushViewController:storyFormatViewContoller
                                               animated:YES];
    }
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

@end
