//
//  MediaPickerViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/27/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "MediaGalleryViewController.h"

@class MediaPickerViewController;

@protocol MediaPickerViewControllerDelegate <NSObject>

- (void)mediaPickerViewController:(MediaPickerViewController *)controller
                   didPickImageAt:(NSString *)path;

@end

@interface MediaPickerViewController : MediaGalleryViewController

@property (nonatomic, weak) id<MediaGalleryViewControllerDelegate, MediaPickerViewControllerDelegate> delegate;
@property (nonatomic, readonly) NSString *selectedMediaPath;

@end
