//
//  NSString+TestNonEmpty.m
//  Yarn
//
//  Created by Mark Jundo Documento on 2/10/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import "NSString+TestNonEmpty.h"

@implementation NSString (TestNonEmpty)

- (BOOL)notEmpty {
    return [self length] > 0;
}

@end
