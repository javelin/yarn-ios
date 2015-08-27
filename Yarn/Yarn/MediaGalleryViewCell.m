//
//  MediaGalleryViewCell.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/26/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "MediaGalleryViewCell.h"
#import "ViewUtils.h"

@implementation MediaGalleryViewCell

static NSString *reuseId = @"MediaGalleryViewCell";

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createViews];
        [self addConstraints];
    }
    
    return self;
}

-(void)createViews {
    INIT_VIEW(UIImageView, _imageView, [self contentView]);
    INIT_VIEW_FILL(UIView, _hightlightView, [self contentView]);
    [_hightlightView setHidden:YES];
    INIT_VIEW(UILabel, _filenameLabel, [self contentView]);
    [_filenameLabel setBackgroundColor:[UIColor clearColor]];
}

- (void)addConstraints {
    CONSTRAINT_EQ(self.contentView, _imageView, Top, [self contentView], Top, 1.0, 0.0);
    CONSTRAINT_EQ(self.contentView, _imageView, CenterX, [self contentView], CenterX, 1.0, 0.0);
    CONSTRAINT_EQ(self.contentView, _imageView, Width, nil, Width, 1.0, [[self class] imageWidth]);
    CONSTRAINT_EQ(self.contentView, _imageView, Height, nil, Height, 1.0, [[self class] imageHeight]);
    
    CONSTRAINT_EQ(self.contentView, _filenameLabel, Bottom, [self contentView], Bottom, 1.0, 0.0);
    CONSTRAINT_EQ(self.contentView, _filenameLabel, Left, [self contentView], Left, 1.0, 0.0);
    CONSTRAINT_EQ(self.contentView, _filenameLabel, Right, [self contentView], Right, 1.0, 0.0);
}

- (void)highlightWithColor:(UIColor *)color {
    [_hightlightView setHidden:NO];
    [_hightlightView setBackgroundColor:[color colorWithAlphaComponent:0.60]];
    [[self contentView] bringSubviewToFront:_hightlightView];
}

- (void)unhighlight {
    [_hightlightView setHidden:YES];
}

- (void)selectWithColor:(UIColor *)color {
    _selectColor = color;
    [_hightlightView setHidden:NO];
    [_hightlightView setBackgroundColor:[color colorWithAlphaComponent:0.30]];
    [[self contentView] bringSubviewToFront:_hightlightView];
}

- (void)deselect {
    [_hightlightView setHidden:YES];
}

+ (CGFloat)imageWidth {
    return IS_IPAD() ? 150:140;
}

+ (CGFloat)imageHeight {
    return IS_IPAD() ? 150:140;
}

+ (NSString *)reuseId {
    return reuseId;
}

@end
