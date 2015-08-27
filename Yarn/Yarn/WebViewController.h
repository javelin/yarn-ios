//
//  WebViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 6/1/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSString *html;
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

- (instancetype)initWithHtml:(NSString *)html;
- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithHtml:(NSString *)html
      showNavigationControls:(BOOL)showNavigationControls;
- (instancetype)initWithPath:(NSString *)path
      showNavigationControls:(BOOL)showNavigationControls;
- (instancetype)initWithURL:(NSURL *)url
     showNavigationControls:(BOOL)showNavigationControls;

+ (instancetype)webViewControllerWithHtml:(NSString *)html;
+ (instancetype)webViewControllerWithPath:(NSString *)path;
+ (instancetype)webViewControllerWithURL:(NSURL *)url;
+ (instancetype)webViewControllerWithHtml:(NSString *)html
                   showNavigationControls:(BOOL)showNavigationControls;
+ (instancetype)webViewControllerWithPath:(NSString *)path
                   showNavigationControls:(BOOL)showNavigationControls;
+ (instancetype)webViewControllerWithURL:(NSURL *)url
                  showNavigationControls:(BOOL)showNavigationControls;

@end
