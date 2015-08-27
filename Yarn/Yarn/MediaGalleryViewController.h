//
//  MediaGalleryViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/26/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MediaGalleryViewController;

@protocol MediaGalleryViewControllerDelegate <NSObject>

@optional
- (void)mediaGalleryViewController:(MediaGalleryViewController *)controller
                  didSelectMediaAt:(NSString *)path;
- (void)mediaGalleryViewController:(MediaGalleryViewController *)controller
                didDeselectMediaAt:(NSString *)path;

@end

@interface MediaGalleryViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, readonly) NSString *basePath;
@property (nonatomic, weak) id<MediaGalleryViewControllerDelegate> delegate;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, readonly) NSString *imagesPath;
@property (nonatomic, readonly) NSDictionary *images;
@property (nonatomic, readonly) NSArray *sortedImageNames;
@property (nonatomic, readonly) NSArray *selectedItemPaths;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) UIBarButtonItem *albumsBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *cameraBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *renameBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *trashBarButtonItem;

- (id)initWithIFId:(NSString *)ifId;

@end
