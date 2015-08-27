//
//  PassageView.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "PassageView.h"
#import "ViewUtils.h"

@interface PassageView() {
    CGPoint _lastCenter;
}

@property (nonatomic, strong) UIAlertController *menuController;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation PassageView

static CGFloat allowance = 10.0;
static CGFloat dimension = 120.0;

@synthesize pos = _pos, linkedIds = _linkedIds;

- (id)initWith:(Passage *)passage delegate:(id<PassageViewDelegate>)delegate {
    self = [super initWithFrame:CGRectMake(0.0, 0.0, dimension, dimension)];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _delegate = delegate;
        _linkedIds = [NSArray array];
        _passage = passage;
        [self setPos:CGPointMake([passage left], [passage top])];
        
        [self setExclusiveTouch:YES];
        
        [self createSubviews];
        [self addConstraints];
        
        [self update];
    }
    return self;
}

- (void)addConstraints {
    CONSTRAINT_EQ(self, _titleLabel, Left, self, Left, 1.0, 3.0);
    CONSTRAINT_EQ(self, _titleLabel, Top, self, Top, 1.0, 3.0);
    CONSTRAINT_EQ(self, _titleLabel, Right, self, Right, 1.0, -3.0);
    CONSTRAINT_EQ(self, _titleLabel, Height, nil, Height, 1.0, 30.0);
    
    CONSTRAINT_EQ(self, _textLabel, Left, self, Left, 1.0, 3.0);
    CONSTRAINT_EQ(self, _textLabel, Top, _titleLabel, Bottom, 1.0, 0.0);
    CONSTRAINT_EQ(self, _textLabel, Right, self, Right, 1.0, -3.0);
    CONSTRAINT_EQ(self, _textLabel, Bottom, self, Bottom, 1.0, -3.0);
    
    CONSTRAINT_EQ(self, _menuButton, Width, nil, Width, 1.0, 32.0);
    CONSTRAINT_EQ(self, _menuButton, Height, nil, Height, 1.0, 32.0);
    CONSTRAINT_EQ(self, _menuButton, Right, self, Right, 1.0, -5.0);
    CONSTRAINT_EQ(self, _menuButton, Bottom, self, Bottom, 1.0, -5.0);
}

- (void)createSubviews {
    INIT_VIEW(UILabel, _titleLabel, self);
    _titleLabel.backgroundColor = [UIColor blueColor];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.text = _passage.name;
    [self addSubview:_titleLabel];
    
    INIT_VIEW(UILabel, _textLabel, self);
    _textLabel.backgroundColor = [UIColor whiteColor];
    _textLabel.textColor = [UIColor blackColor];
    _textLabel.numberOfLines = 0;
    _textLabel.font = [UIFont systemFontOfSize:12.0];
    _textLabel.text = _passage.text;
    _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:_textLabel];
    
    INIT_VIEW(UIButton, _menuButton, self);
    [_menuButton setBackgroundColor:[UIColor lightGrayColor]];
    [_menuButton setImage:[UIImage imageNamed:@"burger"] forState:UIControlStateNormal];
    [_menuButton addTarget:self
                    action:@selector(handleMenuTap)
          forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_menuButton];
}

- (void)setPos:(CGPoint)pos {
    _pos = pos;
    self.passage.top = pos.y;
    self.passage.left = pos.x;
    self.center = CGPointMake(self.frame.size.width / 2 + pos.x,
                              self.frame.size.height / 2 + pos.y);
}

- (void)setStartPassage:(BOOL)startPassage {
    if (startPassage) {
        SetBorderColor(self, [UIColor orangeColor]);
        SetBorderWidth(self, 4.0);
    }
    else {
        SetBorderWidth(self, 0.0);
    }
}

- (void)update {
    self.titleLabel.text = self.passage.name;
    self.textLabel.text = self.passage.text;
}

#pragma mark Delegate
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _lastCenter = [self center];
    [[self superview] bringSubviewToFront:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:[self superview]];
    [self setCenter:location];
    _pos = [self frame].origin;
    _passage.top = _pos.y;
    _passage.left = _pos.x;
    [self setAlpha:0.50];
    [[self superview] setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSAssert([_delegate respondsToSelector:@selector(positionPassageView:)],
             @"id<PassageViewDelegate> should implement positionPassageView:");
    [self setAlpha:1.0];
    [_delegate positionPassageView:self];
    
    [[self superview] setNeedsDisplay];
}

- (void)handleMenuTap {
    NSAssert([_delegate respondsToSelector:@selector(showPassageViewMenu:)],
             @"id<PassageViewDelegate> should implement showPassageViewMenu:");
    [_delegate performSelector:@selector(showPassageViewMenu:) withObject:self];
}

#pragma mark Static methods
+ (CGFloat)allowance {
    return allowance;
}

+ (CGFloat)dimension {
    return dimension;
}

#pragma mark Twine 2 port
- (void)displace:(PassageView *)passageView {
    // Ported from twine 2 code
    // https://bitbucket.org/klembot/twinejs
    
    CGRect tFrame = CGRectInset([self frame], -allowance, -allowance);
    CGRect oFrame = CGRectInset([passageView frame], -allowance, -allowance);
    
    if (!CGRectIntersectsRect(tFrame, oFrame)) {
        return;
    }
    
    CGFloat tLeft = CGRectGetMinX(tFrame);
    CGFloat tRight = CGRectGetMaxX(tFrame);
    CGFloat tTop = CGRectGetMinY(tFrame);
    CGFloat tBottom = CGRectGetMaxY(tFrame);
    
    CGFloat oLeft = CGRectGetMinX(oFrame);
    CGFloat oRight = CGRectGetMaxX(oFrame);
    CGFloat oTop = CGRectGetMinY(oFrame);
    CGFloat oBottom = CGRectGetMaxY(oFrame);
    
    // calculate overlap amounts
    // this is cribbed from
    // http://frey.co.nz/old/2007/11/area-of-two-rectangles-algorithm/
    
    CGFloat xOverlap = MIN(tRight, oRight) - MAX(tLeft, oLeft);
    CGFloat yOverlap = MIN(tBottom, oBottom) - MAX(tTop, oTop);
    
    // resolve horizontal overlap
    
    CGFloat xChange = 0.0, yChange = 0.0;
    
    if (xOverlap != 0.0) {
        CGFloat leftMove = (oLeft - tLeft) + dimension + allowance;
        CGFloat rightMove = tRight - oLeft + allowance;
        
        if (leftMove < rightMove) {
            xChange = -leftMove;
        }
        else {
            xChange = rightMove;
        }
    }
    
    // resolve vertical overlap
    
    if (yOverlap != 0)
    {
        CGFloat upMove = (oTop - tTop) + dimension + allowance;
        CGFloat downMove = tBottom - oTop + allowance;
        
        if (upMove < downMove) {
            yChange = - upMove;
        }
        else {
            yChange = downMove;
        }
    }
    
    // choose the option that moves the other passage the least
    
    if (ABS(xChange) > ABS(yChange)) {
        [passageView setPos:CGPointMake([passageView pos].x, [passageView pos].y + yChange)];
    }
    else {
        [passageView setPos:CGPointMake([passageView pos].x + xChange, [passageView pos].y)];
    }
}

- (CGPoint)bottomSide {
    return CGPointMake([self center].x,
                       _pos.y + CGRectGetHeight([self bounds]));
}

- (CGPoint)bottomLeftCorner {
    return CGPointMake(_pos.x,
                       _pos.y + CGRectGetHeight([self bounds]));
}

- (CGPoint)bottomRightCorner {
    return CGPointMake(_pos.x + CGRectGetWidth([self bounds]),
                       _pos.y + CGRectGetHeight([self bounds]));
}

- (CGPoint)leftSide {
    return CGPointMake(_pos.x, [self center].y);
}

- (CGPoint)rightSide {
    return CGPointMake(_pos.x + CGRectGetWidth([self bounds]),
                       [self center].y);
}

- (CGPoint)topSide {
    return CGPointMake([self center].x, _pos.y);
}

- (CGPoint)topLeftCorner {
    return CGPointMake(_pos.x, _pos.y);
}

- (CGPoint)topRightCorner {
    return CGPointMake(_pos.x + CGRectGetWidth([self bounds]),
                       _pos.y);
}

@end
