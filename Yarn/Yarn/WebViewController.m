//
//  WebViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 6/1/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import "WebViewController.h"
#import "ViewUtils.h"

@interface WebViewController () {
    UIBarButtonItem *_backBarButtonItem;
    UIBarButtonItem *_forwardBarButtonItem;
}

@end

@implementation WebViewController

- (instancetype)initWithHtml:(NSString *)html {
    return [self initWithHtml:html showNavigationControls:NO];
}

- (instancetype)initWithPath:(NSString *)path {
    return [self initWithPath:path showNavigationControls:NO];
}

- (instancetype)initWithURL:(NSURL *)url {
    return [self initWithURL:url showNavigationControls:NO];
}

- (instancetype)initWithHtml:(NSString *)html
      showNavigationControls:(BOOL)showNavigationControls {
    self = [super init];
    if (self) {
        _html = html;
        _url = nil;
        _webView = [UIWebView new];
        _loaded = NO;
        [self setView:_webView];
        
        if (showNavigationControls) {
            _backBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"<"
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(handleGoBackward)];
            [_backBarButtonItem setEnabled:NO];
            _forwardBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@">"
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(handleGoForward)];
            [_forwardBarButtonItem setEnabled:NO];
            [[self navigationItem] setRightBarButtonItems:@[_forwardBarButtonItem,
                                                            _backBarButtonItem]];
        }
        else {
            _backBarButtonItem = nil;
            _forwardBarButtonItem = nil;
        }
    }
    
    return self;
}

- (instancetype)initWithPath:(NSString *)path
      showNavigationControls:(BOOL)showNavigationControls {
    return [self initWithURL:[NSURL fileURLWithPath:path]
      showNavigationControls:showNavigationControls];
}

- (instancetype)initWithURL:(NSURL *)url
     showNavigationControls:(BOOL)showNavigationControls {
    self = [super init];
    if (self) {
        _html = nil;
        _url = url;
        _webView = [UIWebView new];
        _loaded = NO;
        [self setView:_webView];
        
        if (showNavigationControls) {
            _backBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(handleGoBackward)];
            [_backBarButtonItem setEnabled:NO];
            _forwardBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"Forward"
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(handleGoForward)];
            [_forwardBarButtonItem setEnabled:NO];
            [[self navigationItem] setRightBarButtonItems:@[_forwardBarButtonItem,
                                                            _backBarButtonItem]];
        }
        else {
            _backBarButtonItem = nil;
            _forwardBarButtonItem = nil;
        }
    }
    
    return self;
}

+ (instancetype)webViewControllerWithHtml:(NSString *)html {
    return [[WebViewController alloc] initWithHtml:html];
}

+ (instancetype)webViewControllerWithPath:(NSString *)path {
    return [[WebViewController alloc] initWithPath:path];
}

+ (instancetype)webViewControllerWithURL:(NSURL *)url {
    return [[WebViewController alloc] initWithURL:url];
}

+ (instancetype)webViewControllerWithHtml:(NSString *)html
                   showNavigationControls:(BOOL)showNavigationControls {
    return [[WebViewController alloc] initWithHtml:html
                            showNavigationControls:showNavigationControls];
}

+ (instancetype)webViewControllerWithPath:(NSString *)path
                   showNavigationControls:(BOOL)showNavigationControls {
    return [[WebViewController alloc] initWithPath:path
                            showNavigationControls:showNavigationControls];
}

+ (instancetype)webViewControllerWithURL:(NSURL *)url
                  showNavigationControls:(BOOL)showNavigationControls {
    return [[WebViewController alloc] initWithURL:url
                           showNavigationControls:showNavigationControls];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self isLoaded]) {
        _webView.delegate = self;
        SHOW_WAIT();
        if (_url) {
            NSLog(@"Load web page from %@", [_url path]);
            NSURLRequest* req = [NSURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            [_webView loadRequest:req];
        }
        else {
            [_webView loadHTMLString:_html baseURL:[[NSBundle mainBundle] resourceURL]];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Handlers
- (void)handleGoBackward {
    
}

- (void)handleGoForward {
    
}

#pragma mark UIWebViewDelegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    HIDE_WAIT();
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:_LS(@"Error")
                                        message:[_LS(@"Unable to load web page.\n\n") stringByAppendingString:[error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:_LS(@"Close")
                                                        style:UIAlertActionStyleCancel
                                                        handler:nil]];
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"%@", [request URL]);
    NSString *scheme = [[request URL] scheme];
    NSLog(@"%@", scheme);
    if ([scheme isEqualToString:@"http"] ||
        [scheme isEqualToString:@"https"] ||
        [scheme isEqualToString:@"mailto"]) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    HIDE_WAIT();
    _loaded = YES;
    [_backBarButtonItem setEnabled:[webView canGoBack]];
    [_forwardBarButtonItem setEnabled:[webView canGoForward]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

@end
