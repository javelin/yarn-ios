//
//  PassageView.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Passage.h"

@class PassageView;

@protocol PassageViewDelegate <NSObject>

- (BOOL)passageViewCollides:(PassageView *)passageView;
- (void)positionPassageView:(PassageView *)passageView;
- (void)showPassageViewMenu:(PassageView *)passageView;

@end

@interface PassageView : UIView

@property (nonatomic, weak) id<PassageViewDelegate> delegate;
@property (nonatomic, strong) Passage *passage;
@property (nonatomic) CGPoint pos;
@property (nonatomic) BOOL startPassage;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, readonly) CGPoint topSide;
@property (nonatomic, readonly) CGPoint topLeftCorner;
@property (nonatomic, readonly) CGPoint leftSide;
@property (nonatomic, readonly) CGPoint bottomLeftCorner;
@property (nonatomic, readonly) CGPoint bottomSide;
@property (nonatomic, readonly) CGPoint bottomRightCorner;
@property (nonatomic, readonly) CGPoint rightSide;
@property (nonatomic, readonly) CGPoint topRightCorner;

@property (nonatomic, strong) NSArray *linkedIds;

@property (nonatomic, readonly) UIButton *menuButton;

- (id)initWith:(Passage *)passage delegate:(id<PassageViewDelegate>)delegate;
- (void)displace:(PassageView *)passageView;
- (void)update;

+ (CGFloat)allowance;
+ (CGFloat)dimension;

@end
