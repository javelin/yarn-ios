//
//  TextEditorViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextEditorViewController : UIViewController

@property (nonatomic, readonly) UITextView *textView;
@property (nonatomic, copy, setter=setText:) NSString *text;

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text;

@end
