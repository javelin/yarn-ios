//
//  NSData+UTF8String.m
//  Yarn
//
//  Created by Mark Jundo Documento on 5/25/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import "NSData+UTF8String.h"

@implementation NSData (UTF8String)

- (NSString*)UTF8String {
    if (*((const char*)[self bytes] + [self length] - 1) == '\x0') {
        return [self UTF8String];
    }
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end
