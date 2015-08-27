//
//  TextEditorViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "InputAccessoryView.h"
#import "TextEditorViewController.h"
#import "ViewUtils.h"

@interface TextEditorViewController ()

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end

@implementation TextEditorViewController

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text {
    self = [super init];
    if (self) {
        [self createViews];
        [self addConstraints];
        [self setText:text];
        [self setTitle:title];
    }
    
    return self;
}

- (void)addConstraints {
    CONSTRAINT_EQ([self view], _textView, Top, [self view], Top, 1.0, 0.0);
    CONSTRAINT_EQ([self view], _textView, Left, [self view], Left, 1.0, 0.0);
    CONSTRAINT_EQ([self view], _textView, Right, [self view], Right, 1.0, 0.0);
    INIT_CONSTRAINT_EQ(_bottomConstraint, [self view], _textView, Bottom, [self view], Bottom, 1.0, 0.0);
}

- (void)createViews {
    [self setView:[UIView new]];
    [[self view] setBackgroundColor:[UIColor whiteColor]];
    
    InputAccessoryView *inputAccessoryView =
    [[InputAccessoryView alloc] initWithHideHandler:IS_IPAD() ?
                                                nil:^(NSString *title) {
                                                    [[self view] endEditing:YES];
                                                }];
    
    INIT_VIEW(UITextView, _textView, [self view]);
    [_textView setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [_textView setAutocorrectionType:UITextAutocorrectionTypeNo];
    [_textView setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.1]];
    [_textView setFont:[UIFont systemFontOfSize:16.0]];
    [_textView setInputAccessoryView:inputAccessoryView];
    
    [inputAccessoryView addButtonWithTitle:@"(" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@")" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"{" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"}" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"[" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"]" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"\"" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"=" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@":" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@";" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    if (IS_IPAD()) {
        [inputAccessoryView addButtonWithTitle:@"&" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"|" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"." handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setText:(NSString *)text {
    [_textView setText:text];
}

- (NSString *)text {
    return [_textView text];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
}

#pragma mark Keyboard notifications
- (void)keyboardWillHide:(NSNotification *)sender {
    [self adjustTextViewWhenKeyboardWillShow:NO notification:sender];
}

- (void)keyboardWillShow:(NSNotification *)sender {
    [self adjustTextViewWhenKeyboardWillShow:YES notification:sender];
}

- (void)adjustTextViewWhenKeyboardWillShow:(BOOL)shown notification:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect keyboardFrame = [[self view] convertRect:keyboardEndFrame toView:nil];
    [_bottomConstraint setConstant:shown ? -CGRectGetHeight(keyboardFrame):0.0];
    [[self view] setNeedsLayout];
    [[self view] layoutIfNeeded];
    
    [UIView commitAnimations];
}

@end
