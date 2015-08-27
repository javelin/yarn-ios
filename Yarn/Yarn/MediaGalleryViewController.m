//
//  MediaGalleryViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/26/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "MediaGalleryViewCell.h"
#import "MediaGalleryViewController.h"
#import "NSObject+Associative.h"
#import "ViewUtils.h"

@interface MediaGalleryViewController () {
    NSMutableDictionary *_images;
    NSMutableArray *_selectedItemPaths;
    BOOL _shouldReload;
}

@end

@implementation MediaGalleryViewController

- (id)initWithIFId:(NSString *)ifId {
    self = [super init];
    if (self) {
        _basePath = [[AppDirectory() stringByAppendingPathComponent:@"stories"]
                     stringByAppendingPathComponent:ifId];
        _imagesPath = [_basePath stringByAppendingPathComponent:@"images"];
        _images = nil;
        _shouldReload = YES;
        _delegate = nil;
        _selectedItemPaths = [NSMutableArray array];
        
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
        if (IS_IPAD()) {
            [self setTitle:_LS(@"Organize Media")];
        }
        
        [self createViews];
        
        _trashBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                      target:self
                                                      action:@selector(handleDeleteSelected)];
        [_trashBarButtonItem setEnabled:NO];
        
        _renameBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:_LS(@"Rename")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleRenameSelected)];
        [_renameBarButtonItem setEnabled:NO];
        
        _albumsBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"photo-album"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleImportFromAlbums)];
        
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            _cameraBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                          target:self
                                                          action:@selector(handleImportFromCamera)];
            [[self navigationItem] setRightBarButtonItems:@[_renameBarButtonItem,
                                                            _trashBarButtonItem,
                                                            _albumsBarButtonItem,
                                                            _cameraBarButtonItem]];
        }
        else {
            [[self navigationItem] setRightBarButtonItems:@[_trashBarButtonItem,
                                                            _renameBarButtonItem,
                                                            _albumsBarButtonItem]];
        }
    }
    
    return self;
}

- (void)createViews {
    [self setView:[UIView new]];
    [[self view] setBackgroundColor:[UIColor whiteColor]];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    [layout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [layout setItemSize:CGSizeMake([MediaGalleryViewCell imageWidth],
                                   [MediaGalleryViewCell imageHeight] + 30.0)];
    [layout setMinimumInteritemSpacing:20.0];
    [layout setMinimumLineSpacing:20.0];
    [layout setSectionInset:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
    
    _collectionView =
    [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [_collectionView setBackgroundColor:[UIColor clearColor]];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    [_collectionView setAllowsSelection:YES];
    [_collectionView setAllowsMultipleSelection:YES];
    [_collectionView registerClass:[MediaGalleryViewCell class]
            forCellWithReuseIdentifier:[MediaGalleryViewCell reuseId]];
    ADD_SUBVIEW_FILL([self view], _collectionView);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_shouldReload) {
        SHOW_WAIT();
        DispatchAsync(^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error = nil;
            _images = [NSMutableDictionary dictionary];
            for (NSString *fname in [fileManager contentsOfDirectoryAtPath:_imagesPath error:&error]) {
                error = nil;
                NSString *path = [_imagesPath stringByAppendingPathComponent:fname];
                UIImage *img = [UIImage imageWithContentsOfFile:path];
                UIImage *scaledImg = [self imageWithImage:img
                                         scaledToFillSize:CGSizeMake([MediaGalleryViewCell imageWidth],
                                                                     [MediaGalleryViewCell imageHeight])];
                NSDictionary *attribs = [fileManager attributesOfItemAtPath:path error:&error];
                if (!error) {
                    NSDate *dateModified = [attribs objectForKey:NSFileModificationDate];
                    [scaledImg setAssociateObject:dateModified forKey:@"date-modified"];
                }
                else {
                    NSLog(@"%@", error.localizedDescription);
                    [scaledImg setAssociateObject:[NSDate date] forKey:@"date-modified"];
                }
                [_images setObject:scaledImg forKey:fname];
            }
            [self updateSortedNames];
            
            DispatchAsyncMain(^{
                HIDE_WAIT();
                [_collectionView reloadData];
            });
        });
    }
    
    _shouldReload = NO;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (!parent) {
        [_selectedItemPaths removeAllObjects];
        [self updateBarButtonItems];
        [_collectionView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Handlers
- (void)handleDeleteSelected {
    NSAssert(_selectedItemPaths.count > 0, @"We must have something to delete");
    AlertQuestion(_LS(@"Media"),
                  _LS(@"Deleting media file(s) may break elements of your story. Do you want to continue?"),
                  _LS(@"Cancel"),
                  _LS(@"Delete"),
                  YES,
                  ^(UIAlertAction *action) {
                      SHOW_WAIT();
                      DispatchAsync(^{
                          NSFileManager *manager = [NSFileManager defaultManager];
                          NSInteger failures = 0;
                          for (NSString *path in _selectedItemPaths) {
                              NSError *error = nil;
                              [manager removeItemAtPath:path error:&error];
                              if (!error) {
                                  [_images removeObjectForKey:path.lastPathComponent];
                              }
                              else {
                                  NSLog(@"%@", error.localizedDescription);
                                  ++failures;
                              }
                          }
                          [self updateSortedNames];
                          dispatch_async(dispatch_get_main_queue(), ^{
                              HIDE_WAIT();
                              if (failures) {
                                  AlertError(_LS(@"Some items cannot be deleted."),
                                             self);
                              }
                              [_selectedItemPaths removeAllObjects];
                              [self updateBarButtonItems];
                              [_collectionView reloadData];
                          });
                      });
                  },
                  self);
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)handleImportFromAlbums {
    UIImagePickerController *picker = [UIImagePickerController new];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setDelegate:self];
    [picker setAllowsEditing:YES];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)handleImportFromCamera {
    UIImagePickerController *picker = [UIImagePickerController new];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [picker setDelegate:self];
    [picker setAllowsEditing:YES];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)renameFileAt:(NSString *)oldPath to:(NSString *)newPath {
    NSString *newName = newPath.lastPathComponent;
    NSString *cleanName = [newName stringByReplacingOccurrencesOfString:@"[^a-zA-Z0-9_-\\. ]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, newName.length)];
    if (![cleanName isEqualToString:newName]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:_LS(@"Rename Error") message:_LS(@"New name contains invalid characters. File was not renamed.") delegate:nil cancelButtonTitle:_LS(@"OK") otherButtonTitles:nil];
        [av show];
    }
    else if (![newName isEqualToString:oldPath.lastPathComponent]) {
        newName = [newName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        if (![newName.pathExtension isEqualToString:oldPath.pathExtension]) {
            newName = [newName stringByAppendingPathExtension:oldPath.pathExtension];
        }
        newName = [_imagesPath stringByAppendingPathComponent:newName];
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newName error:&error];
        if (error) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:_LS(@"Rename Error") message:error.localizedDescription delegate:nil cancelButtonTitle:_LS(@"OK") otherButtonTitles:nil];
            [av show];
        }
        [_images setObject:[_images objectForKey:oldPath.lastPathComponent] forKey:newName.lastPathComponent];
        [_images removeObjectForKey:oldPath.lastPathComponent];
        [_selectedItemPaths removeAllObjects];
        [self updateSortedNames];
        [self updateBarButtonItems];
        [_collectionView reloadData];
    }
}

- (void)handleRenameSelected {
    NSAssert(_selectedItemPaths.count == 1, @"Cannot rename multiple files.");
    NSString *oldPath = [_selectedItemPaths firstObject];
    
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:_LS(@"Rename File")
                                        message:_LS(@"Renaming this file may break elements in your story.\nAre you sure?")
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Cancel")
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    
    
    NSString *msg = [NSString stringWithFormat:_LS(@"Enter new name for %@."), [oldPath lastPathComponent]];
    UIAlertController *renameController =
    [UIAlertController alertControllerWithTitle:_LS(@"Rename File")
                                        message:msg
                                 preferredStyle:UIAlertControllerStyleAlert];
    [renameController addTextFieldWithConfigurationHandler:^(UITextField * __nonnull textField) {
        [textField setPlaceholder:_LS(@"Filename")];
    }];
    [renameController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Cancel")
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    UITextField *textField = [[renameController textFields] firstObject];
    [alertController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Rename")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * __nonnull action) {
                                NSString *newPath = TRIM([textField text]);
                                [self renameFileAt:[oldPath lastPathComponent] to:newPath];
                            }]];
    
    [renameController addAction:
     [UIAlertAction actionWithTitle:_LS(@"Rename")
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * __nonnull action) {
                                [self presentViewController:alertController
                                                   animated:YES
                                                 completion:nil];
                            }]];
    [self presentViewController:renameController
                       animated:YES
                     completion:^{
                         
                     }];
}

- (void)updateSortedNames {
    _sortedImageNames = [_images.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *a = obj1, *b = obj2;
        NSDate *aDate = [[_images objectForKey:a] getAssociatedObjectForKey:@"date-modified"];
        NSDate *bDate = [[_images objectForKey:b] getAssociatedObjectForKey:@"date-modified"];
        return [bDate compare:aDate];
    }];
}

- (void)updateBarButtonItems {
    _renameBarButtonItem.enabled = _selectedItemPaths.count == 1;
    _trashBarButtonItem.enabled = _selectedItemPaths.count > 0;
}

#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _sortedImageNames.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaGalleryViewCell *cell = (MediaGalleryViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[MediaGalleryViewCell reuseId] forIndexPath:indexPath];
    
    [[cell imageView] setImage:[_images objectForKey:[_sortedImageNames objectAtIndex:[indexPath row]]]];
    [[cell filenameLabel] setText:[[_sortedImageNames objectAtIndex:[indexPath row]] stringByDeletingPathExtension]];
    [cell deselect];
    
    return cell;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectedMediaPath = [_imagesPath stringByAppendingPathComponent:[_sortedImageNames objectAtIndex:indexPath.row]];
    [_delegate performSelector:@selector(mediaGalleryViewController:didDeselectMediaAt:) withObject:self withObject:selectedMediaPath];
    [_selectedItemPaths removeObject:selectedMediaPath];
    
    MediaGalleryViewCell *cell = (MediaGalleryViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell deselect];
    
    [self updateBarButtonItems];
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaGalleryViewCell *cell = (MediaGalleryViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell highlightWithColor:[UIColor redColor]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectedMediaPath = [_imagesPath stringByAppendingPathComponent:[_sortedImageNames objectAtIndex:indexPath.row]];
    [_delegate performSelector:@selector(mediaGalleryViewController:didSelectMediaAt:) withObject:self withObject:selectedMediaPath];
    [_selectedItemPaths addObject:selectedMediaPath];
    
    MediaGalleryViewCell *cell = (MediaGalleryViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell selectWithColor:[UIColor redColor]];
    
    [self updateBarButtonItems];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaGalleryViewCell *cell = (MediaGalleryViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell unhighlight];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self dismissViewControllerAnimated:YES completion:^{
        NSData *data = UIImageJPEGRepresentation(image, 1.0);
        NSString *fname = [_dateFormatter stringFromDate:[NSDate date]];
        fname = [fname stringByAppendingPathExtension:@"jpg"];
        NSString *savePath = [_imagesPath stringByAppendingPathComponent:fname];
        NSLog(@"%@", savePath);
        [data writeToFile:savePath atomically:YES];
        UIImage *scaledImg = [self imageWithImage:image
                                 scaledToFillSize:CGSizeMake([MediaGalleryViewCell imageWidth],
                                                             [MediaGalleryViewCell imageHeight])];
        [scaledImg setAssociateObject:[NSDate date] forKey:@"date-modified"];
        [_images setObject:scaledImg forKey:fname];
        [self updateSortedNames];
        [_collectionView reloadData];
        
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:_LS(@"Rename Saved Image")
                                            message:_LS(@"Enter a new name for the new image file.")
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * __nonnull textField) {
            [textField setPlaceholder:_LS(@"Filename")];
        }];
        UITextField *textField = [[alertController textFields] firstObject];
        [alertController addAction:
         [UIAlertAction actionWithTitle:_LS(@"Save")
                                  style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * __nonnull action) {
                                    NSString *newPath = TRIM([textField text]);
                                    if ([newPath notEmpty]) {
                                        [self renameFileAt:savePath
                                                        to:[_imagesPath stringByAppendingPathComponent:newPath]];
                                    }
                                }]];
        NSString *filename = [fname stringByDeletingPathExtension];
        [self presentViewController:alertController
                           animated:YES
                         completion:^{
                             [textField setMarkedText:filename
                                        selectedRange:NSMakeRange(0, [filename length])];
                         }];
    }];
}

@end
