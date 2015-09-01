//
//  AppDelegate.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/12/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppDataDelegate <NSObject>

- (BOOL)importData:(NSURL *)url;
- (void)saveData;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) id<AppDataDelegate> delegate;

@end

