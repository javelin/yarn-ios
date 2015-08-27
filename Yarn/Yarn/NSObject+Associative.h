//
//  NSObject+Associative.h
//  Yarn
//
//  Created by Mark Jundo P. Documento on 2/22/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Associative)

- (void)setAssociateObject:(id)object forKey:(NSString *)key;
- (id)getAssociatedObjectForKey:(NSString *)key;

@end
