//
//  EditPassageViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/20/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "InputAccessoryView.h"
#import "PassageEditorViewController.h"
#import "ViewUtils.h"

@interface PassageEditorViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tagsLabel;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextField *tagsField;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) UIBarButtonItem* closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem* hideKeyboardButtonItem;
@property (nonatomic, strong) UIBarButtonItem* trashButtonItem;
@property (nonatomic, strong) UIBarButtonItem* imageLinkButtonItem;
@property (nonatomic, strong) UIBarButtonItem* redoButtonItem;
@property (nonatomic, strong) UIBarButtonItem* undoButtonItem;

@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end

@implementation PassageEditorViewController

- (id)initWithPassageView:(PassageView *)passageView
                 delegate:(id<PassageEditorViewControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _passageView = passageView;
        _delegate = delegate;
        
        [self createViews];
        [self addConstraints];
        
        _hideKeyboardButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hide-keyboard"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleHideKeyboard)];
        
        _trashButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                      target:self
                                                      action:@selector(handleDeleteThisPassage)];
        
        _imageLinkButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"photo"]
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(handleAddImageLink)];
        _imageLinkButtonItem.enabled = NO;
        
        _undoButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo
                                                      target:self
                                                      action:@selector(handleUndoEdit)];
        _undoButtonItem.enabled = NO;
        
        _redoButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRedo
                                                      target:self
                                                      action:@selector(handleRedoEdit)];
        _redoButtonItem.enabled = NO;
        
        [[self navigationItem] setRightBarButtonItems:@[_redoButtonItem,
                                                        _undoButtonItem,
                                                        _imageLinkButtonItem,
                                                        _trashButtonItem]];
        
        if (IS_IPAD()) {
            [self setTitle:_LS(@"Edit Passage")];
        }
    }
    
    return self;
}

- (void)addConstraints {
    CONSTRAINT_EQ([self view], _titleLabel, Left, [self view], Left, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _titleLabel, Width, nil, Width, 1.0, MAX(CGRectGetWidth([_titleLabel frame]),
                                                                        CGRectGetWidth([_tagsLabel frame])));
    CONSTRAINT_EQ([self view], _titleLabel, CenterY, _titleField, CenterY, 1.0, 0.0);
    
    CONSTRAINT_EQ([self view], _tagsLabel, Left, [self view], Left, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _tagsLabel, Right, _titleLabel, Right, 1.0, 0.0);
    CONSTRAINT_EQ([self view], _tagsLabel, CenterY, _tagsField, CenterY, 1.0, 0.0);
    
    INIT_CONSTRAINT_EQ(_topConstraint, [self view], _titleField, Top, [self view], Top, 1.0, 10.0);
    //CONSTRAINT_EQ([self view], _titleField, Top, [self view], Top, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _titleField, Left, _titleLabel, Right, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _titleField, Right, [self view], Right, 1.0, -10.0);
    CONSTRAINT_EQ([self view], _titleField, Height, nil, Height, 1.0, 30.0);
    
    CONSTRAINT_EQ([self view], _tagsField, Left, _tagsLabel, Right, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _tagsField, Top, _titleField, Bottom, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _tagsField, Right, [self view], Right, 1.0, -10.0);
    CONSTRAINT_EQ([self view], _tagsField, Height, nil, Height, 1.0, 30.0);
    
    CONSTRAINT_EQ([self view], _textView, Left, [self view], Left, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _textView, Top, _tagsField, Bottom, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _textView, Right, [self view], Right, 1.0, -10.0);
    INIT_CONSTRAINT_EQ(_bottomConstraint, [self view], _textView, Bottom, [self view], Bottom, 1.0, -10.0);
}

- (void)createViews {
    [[self view] setBackgroundColor:[UIColor whiteColor]];
    
    INIT_VIEW(UILabel, _titleLabel, [self view]);
    [_titleLabel setBackgroundColor:[UIColor clearColor]];
    [_titleLabel setTextColor:[UIColor blackColor]];
    [_titleLabel setText:_LS(@"Title")];
    [_titleLabel sizeToFit];
    
    INIT_VIEW(UILabel, _tagsLabel, [self view]);
    [_tagsLabel setBackgroundColor:[UIColor clearColor]];
    [_tagsLabel setTextColor:[UIColor blackColor]];
    [_tagsLabel setText:_LS(@"Tags")];
    [_tagsLabel sizeToFit];
    
    INIT_VIEW(UITextField, _titleField, [self view]);
    [_titleField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [_titleField setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.1]];
    [_titleField setBorderStyle:UITextBorderStyleLine];
    [_titleField setDelegate:self];
    [_titleField setText:[[_passageView passage] name]];
    [_titleField setTextColor:[UIColor blackColor]];
    [_titleField addTarget:self
                    action:@selector(textFieldDidChange:)
          forControlEvents:UIControlEventEditingChanged];
    
    INIT_VIEW(UITextField, _tagsField, [self view]);
    [_tagsField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [_tagsField setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.1]];
    [_tagsField setBorderStyle:UITextBorderStyleLine];
    [_tagsField setDelegate:self];
    [_tagsField setPlaceholder:_LS(@"(separated by spaces)")];
    [_tagsField setText:[[[_passageView passage] tags] componentsJoinedByString:@" "]];
    [_tagsField setTextColor:[UIColor blackColor]];
    [_tagsField addTarget:self
                   action:@selector(textFieldDidChange:)
         forControlEvents:UIControlEventEditingChanged];
    
    InputAccessoryView *inputAccessoryView =
    [[InputAccessoryView alloc] initWithHideHandler:nil];
    INIT_VIEW(UITextView, _textView, [self view]);
    [_textView setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    [_textView setAutocorrectionType:UITextAutocorrectionTypeDefault];
    [_textView setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.1]];
    [_textView setDelegate:self];
    [_textView setFont:[_titleField font]];
    [_textView setInputAccessoryView:inputAccessoryView];
    [_textView setText:[[_passageView passage] text]];
    [_textView setTextColor:[UIColor blackColor]];
    [inputAccessoryView addButtonWithTitle:@"[" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"|" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"]" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"<" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@">" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"$" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"\"" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"=" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"." handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    [inputAccessoryView addButtonWithTitle:@"@@" handler:^(NSString *title) {
        [_textView replaceRange:_textView.selectedTextRange withText:title];
    }];
    
    if (IS_IPAD()) {
        [inputAccessoryView addButtonWithTitle:@"!" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"''" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"__" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"//" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"==" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"~~" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
        [inputAccessoryView addButtonWithTitle:@"^^" handler:^(NSString *title) {
            [_textView replaceRange:_textView.selectedTextRange withText:title];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)willMoveToParentViewController:(nullable UIViewController *)parent {
    if (!parent) {
        [self handleDoneEditing];
        NSAssert([_delegate respondsToSelector:@selector(passageEditorViewController:didFinish:)],
                 @"id<PassageEditorViewControllerDelegate> must implement passageEditorViewController:didFinish:");
        [_delegate performSelector:@selector(passageEditorViewController:didFinish:)
                        withObject:self
                        withObject:_passageView];
    }
}

#pragma mark Autosave
- (void)autosave {
    [super autosave];
    [self updatePassage];
    NSAssert([_delegate respondsToSelector:@selector(passageEditorViewController:requestsToSave:)], @"id<PassageEditorViewControllerDelegate> must implement passageEditorViewController:requestsToSave:");
    [_delegate passageEditorViewController:self
                            requestsToSave:_passageView];
}

#pragma mark Handlers
- (void)handleAddImageLink {
    MediaPickerViewController *pickerViewController =
    [_delegate mediaPickerViewControllerForEditor:self];
    [pickerViewController setTitle:_LS(@"Add Image Link")];
    [pickerViewController setDelegate:self];
    [[self navigationController] pushViewController:pickerViewController
                                           animated:YES];
}

- (void)handleDeleteThisPassage {
    AlertQuestion(_LS(@"Delete This Passage"),
                  _LS(@"This action is permanent and cannot be undone.\nAre you sure?"),
                  _LS(@"Cancel"),
                  _LS(@"Delete"),
                  YES,
                  ^(UIAlertAction *action) {
                      NSAssert([_delegate respondsToSelector:@selector(passageEditorViewController:requestsToDelete:)], @"id<PassageEditorViewControllerDelegate> must implement passageEditorViewController:requestsToDelete:");
                      [_delegate passageEditorViewController:self
                                            requestsToDelete:_passageView];
                      _passageView = nil;
                      [[self navigationController] popViewControllerAnimated:YES];
                  },
                  self);
}

- (void)handleDoneEditing {
    [self invalidateAutosaveTimer];
    [self updatePassage];
}

- (void)handleHideKeyboard {
    [[self view] endEditing:YES];
}

- (void)handleRedoEdit {
    void (^redo_)(UIResponder *responder) = ^(UIResponder *responder) {
        if ([responder isFirstResponder] &&
            [[responder undoManager] canRedo]) {
            [[responder undoManager] redo];
            [_undoButtonItem setEnabled:[[responder undoManager] canUndo]];
            [_redoButtonItem setEnabled:[[responder undoManager] canRedo]];
        }
    };
    redo_(_titleField);
    redo_(_tagsField);
    redo_(_textView);
}

- (void)handleUndoEdit {
    void (^undo_)(UIResponder *responder) = ^(UIResponder *responder) {
        if ([responder isFirstResponder] &&
            [[responder undoManager] canUndo]) {
            [[responder undoManager] undo];
            [_undoButtonItem setEnabled:[[responder undoManager] canUndo]];
            [_redoButtonItem setEnabled:[[responder undoManager] canRedo]];
        }
    };
    undo_(_titleField);
    undo_(_tagsField);
    undo_(_textView);
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
    [_bottomConstraint setConstant:shown ? -CGRectGetHeight(keyboardFrame) - 10:-10];
    [[self view] setNeedsLayout];
    [[self view] layoutIfNeeded];
    
    [_closeButtonItem setEnabled:!shown];
    [_trashButtonItem setEnabled:!shown];
    if (!IS_IPAD()) {
        [[self navigationItem] setLeftBarButtonItem:shown ? _hideKeyboardButtonItem:_closeButtonItem];
    }
    
    [UIView commitAnimations];
}

#pragma mark Other methods
- (NSString *)name {
    return [[_titleField text] stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
}

- (NSArray *)tags {
    NSMutableSet *tags = [NSMutableSet set];
    for (NSString *tag in [[_tagsField text] componentsSeparatedByString:@" "]) {
        [tags addObject:[tag stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]]];
    }
    return [tags allObjects];
}

- (NSString *)text {
    return [_textView text];
}

- (void)updatePassage {
    if (_passageView) {
        if (![[[_passageView passage] name] isEqualToString:[self name]]) {
            NSAssert([_delegate respondsToSelector:@selector(passageEditorViewController:passageNameDidChangeFor:)],
                     @"id<PassageEditorViewControllerDelegate> must implement passageEditorViewController:passageNameDidChangeFor:");
            [_delegate passageEditorViewController:self
                           passageNameDidChangeFor:_passageView];
            [[_passageView passage] setName:[self name]];
        }
        [[_passageView passage] setTags:[self tags]];
        [[_passageView passage] setText:[self text]];
    }
}

#pragma mark MediaPickerViewControllerDelegate
- (void)mediaPickerViewController:(MediaPickerViewController *)controller
                   didPickImageAt:(NSString *)path {
    NSString *relativePath = [[[path stringByDeletingLastPathComponent] lastPathComponent]
                              stringByAppendingPathComponent:[path lastPathComponent]];
    NSLog(@"%@", relativePath);
    NSString *link = [NSString stringWithFormat:@"<img src=\"%@\" />", relativePath];
    [_textView replaceRange:[_textView selectedTextRange] withText:link];
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(nonnull UITextField *)textField {
    [_undoButtonItem setEnabled:[[textField undoManager] canUndo]];
    [_redoButtonItem setEnabled:[[textField undoManager] canRedo]];
}

- (void)textFieldDidChange:(UITextField *)textField {
    [_undoButtonItem setEnabled:[[textField undoManager] canUndo]];
    [_redoButtonItem setEnabled:[[textField undoManager] canRedo]];
    [self startAutosaveTimer];
}

- (void)textFieldDidEndEditing:(nonnull UITextField *)textField {
    [_undoButtonItem setEnabled:NO];
    [_redoButtonItem setEnabled:NO];
}

- (BOOL)textFieldShouldReturn:(nonnull UITextField *)textField {
    if (IS_IPAD()) {
        if (textField == _titleField) {
            [_tagsField becomeFirstResponder];
        }
        else if (textField == _tagsField) {
            [_textView becomeFirstResponder];
        }
    }
    else {
        [textField resignFirstResponder];
    }
    return NO;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(nonnull UITextView *)textView {
    [_topConstraint setConstant:-70];
    [_undoButtonItem setEnabled:[[textView undoManager] canUndo]];
    [_redoButtonItem setEnabled:[[textView undoManager] canRedo]];
    [_imageLinkButtonItem setEnabled:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    [_undoButtonItem setEnabled:[[textView undoManager] canUndo]];
    [_redoButtonItem setEnabled:[[textView undoManager] canRedo]];
    [self startAutosaveTimer];
}

- (void)textViewDidEndEditing:(nonnull UITextView *)textView {
    [_topConstraint setConstant:10];
    [_undoButtonItem setEnabled:NO];
    [_redoButtonItem setEnabled:NO];
    [_imageLinkButtonItem setEnabled:NO];
}

@end
