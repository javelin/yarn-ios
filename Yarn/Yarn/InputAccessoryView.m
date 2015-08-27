//
//  InputAccessoryView.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/20/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "InputAccessoryView.h"
#import "ViewUtils.h"

@interface InputAccessoryView()

@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableDictionary *handlers;
@property (nonatomic, strong) UIButton *hideButton;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSLayoutConstraint *rightConstraint;

@end

@implementation InputAccessoryView

- (instancetype)initWithHideHandler:(void (^)(NSString *title))handler {
    self = [super initWithFrame:CGRectMake(0, 0, 0, [[self class] height])];
    if (self) {
        _buttons = [NSMutableArray array];
        _handlers = [NSMutableDictionary dictionary];
        //[self setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.3]];
        [self setBackgroundColor:[UIColor whiteColor]];
        
        INIT_VIEW(UIView, _contentView, self);
        [_contentView setBackgroundColor:[UIColor clearColor]];
        CONSTRAINT_EQ(self, _contentView, Top, self, Top, 1.0, 0.0);
        CONSTRAINT_EQ(self, _contentView, Bottom, self, Bottom, 1.0, 0.0);
        CONSTRAINT_EQ(self, _contentView, CenterX, self, CenterX, 1.0, 0.0);
        
        _font = [UIFont systemFontOfSize:22.0];
        if (handler) {
            _hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
            if (IS_IPAD()) {
                [[_hideButton titleLabel] setFont:_font];
            }
            [_hideButton setBackgroundColor:[UIColor lightGrayColor]];
            [_hideButton setTitle:_LS(@"Hide") forState:UIControlStateNormal];
            [_hideButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_hideButton sizeToFit];
            ADD_SUBVIEW(_contentView, _hideButton);
            CONSTRAINT_EQ(_contentView, _hideButton, Top, _contentView, Top, 1.0, 0.0);
            CONSTRAINT_EQ(_contentView, _hideButton, Right, _contentView, Right, 1.0, 0.0);
            CONSTRAINT_EQ(_contentView, _hideButton, Height, _contentView, Height, 1.0, 0.0);
            CONSTRAINT_GEQ(_contentView, _hideButton, Width, nil, Width, 1.0, [[self class] minButtonWidth]);
            [_hideButton addTarget:self action:@selector(handleDidTapButton:)
                  forControlEvents:UIControlEventTouchUpInside];
            [_handlers setObject:handler forKey:_LS(@"Hide")];
        }
        else {
            _hideButton = nil;
        }
    }
    
    return self;
}

- (void)addButtonWithTitle:(NSString *)title
                   handler:(void (^)(NSString *title))handler {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if (IS_IPAD()) {
        [[button titleLabel] setFont:_font];
    }
    [button setBackgroundColor:[UIColor lightGrayColor]];
    [button setTitle:[NSString stringWithFormat:@"%@", title] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //[button sizeToFit];
    
    ADD_SUBVIEW(_contentView, button);
    CONSTRAINT_EQ(_contentView, button, Top, _contentView, Top, 1.0, 0.0);
    if ([_buttons lastObject]) {
        CONSTRAINT_EQ(_contentView, button, Left, [_buttons lastObject], Right, 1.0, 2.0);
    }
    else {
        CONSTRAINT_EQ(_contentView, button, Left, _contentView, Left, 1.0, 0.0);
    }
    CONSTRAINT_EQ(_contentView, button, Bottom, _contentView, Bottom, 1.0, 0.0);
    
    CGFloat width = ceil([title sizeWithAttributes:@{ NSFontAttributeName:[[button titleLabel] font] }].width);
    CONSTRAINT_EQ(_contentView, button, Width, nil, Width, 1.0, MAX(width, [[self class] minButtonWidth]));
    
    if (_rightConstraint) {
        [_contentView removeConstraint:_rightConstraint];
    }
    
    if (_hideButton) {
        INIT_CONSTRAINT_EQ(_rightConstraint, _contentView, button, Right, _hideButton, Left, 1.0, -2.0);
    }
    else {
        INIT_CONSTRAINT_EQ(_rightConstraint, _contentView, _contentView, Right, button, Right, 1.0, 2.0);
    }
    
    [button addTarget:self action:@selector(handleDidTapButton:)
     forControlEvents:UIControlEventTouchUpInside];
    
    [_buttons addObject:button];
    if (handler) {
        [_handlers setObject:handler forKey:TRIM(title)];
    }
}

- (void)handleDidTapButton:(UIButton *)sender {
    NSString *title = TRIM([[sender titleLabel] text]);
    void (^handler)(NSString *title) = [_handlers objectForKey:title];
    if (handler) {
        handler(title);
    }
}

+ (CGFloat)height {
    return IS_IPAD() ? 48:36;
}

+ (CGFloat)minButtonWidth {
    return IS_IPAD() ? 50:25;
}

@end
