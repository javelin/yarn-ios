//
//  InputAccessoryView.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/20/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InputAccessoryView : UIView

- (instancetype)initWithHideHandler:(void (^)(NSString *title))handler;
- (void)addButtonWithTitle:(NSString *)title
                   handler:(void (^)(NSString *title))handler;

+ (CGFloat)height;

@end
