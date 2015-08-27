//
//  EditPassageViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/20/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "AutosavingViewController.h"
#import "MediaPickerViewController.h"
#import "PassageView.h"

@class PassageEditorViewController;

@protocol PassageEditorViewControllerDelegate <NSObject>

- (void)passageEditorViewController:(PassageEditorViewController *)controller
                          didFinish:(PassageView *)passageView;
- (void)passageEditorViewController:(PassageEditorViewController *)controller
            passageNameDidChangeFor:(PassageView *)passageView;
- (void)passageEditorViewController:(PassageEditorViewController *)controller
                   requestsToDelete:(PassageView *)passageView;
- (void)passageEditorViewController:(PassageEditorViewController *)controller
                     requestsToSave:(PassageView *)passageView;
- (MediaPickerViewController *)mediaPickerViewControllerForEditor:(PassageEditorViewController *)controller;

@end

@interface PassageEditorViewController : AutosavingViewController <MediaGalleryViewControllerDelegate, MediaPickerViewControllerDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, weak) id<PassageEditorViewControllerDelegate> delegate;
@property (nonatomic, readonly) PassageView *passageView;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *tags;
@property (nonatomic, readonly) NSString *text;

- (id)initWithPassageView:(PassageView *)passageView
                 delegate:(id<PassageEditorViewControllerDelegate>)delegate;

@end
