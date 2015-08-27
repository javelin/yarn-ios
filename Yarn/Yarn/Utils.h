//
//  Utils.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#ifndef Yarn_Utils_h
#define Yarn_Utils_h

#import <Foundation/Foundation.h>
#import "NSData+UTF8String.h"
#import "NSObject+Associative.h"
#import "NSString+TestNonEmpty.h"

typedef void (^ErrorBlock)(NSError *error);

void DispatchAsync(dispatch_block_t block);
void DispatchAsyncMain(dispatch_block_t block);

#define BUNDLE_VALUE(key) [[[NSBundle mainBundle] infoDictionary] objectForKey:key]

//#define DISPATCH_ASYNC(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
#define DISPATCH_ASYNC DispatchAsync

//#define DISPATCH_ASYNC_MAIN(block) dispatch_async(dispatch_get_main_queue(), block)
#define DISPATCH_ASYNC_MAIN DispatchAsyncMain

#define _LS(s) NSLocalizedString(s, nil)

#define TRIM(s) [(s) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]

NSString *AppDirectory();
NSString *AppName();
NSString *AppVersion();
NSString *SanitizeString(NSString *s, BOOL showLinks);
NSString *TwineVersion();
NSString *XMLEscape(NSString *string);

#endif
