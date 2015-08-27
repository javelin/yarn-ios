//
//  NSObject+Associative.m
//  Yarn
//
//  Created by Mark Jundo P. Documento on 2/22/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+Associative.h"

@implementation NSObject (Associative)

- (void)setAssociateObject:(id)object forKey:(NSString *)key {
    objc_setAssociatedObject(self, (__bridge const void *)(key), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)getAssociatedObjectForKey:(NSString *)key {
    return objc_getAssociatedObject(self, (__bridge const void *)(key));
}

@end
