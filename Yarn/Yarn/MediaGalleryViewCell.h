//
//  MediaGalleryViewCell.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/26/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaGalleryViewCell : UICollectionViewCell

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIView *hightlightView;
@property (nonatomic, readonly) UILabel *filenameLabel;
@property (nonatomic, copy) UIColor *selectColor;

+ (CGFloat)imageWidth;
+ (CGFloat)imageHeight;
+ (NSString *)reuseId;

- (void)highlightWithColor:(UIColor *)color;
- (void)unhighlight;
- (void)selectWithColor:(UIColor *)color;
- (void)deselect;

@end
