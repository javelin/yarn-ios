//
//  Regex.h
//  Yarn
//
//  Created by Mark Jundo Documento on 2/10/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegexMatch : NSObject

@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, retain) NSString *source;
@property (nonatomic, readonly, getter=getCount) NSUInteger count;

- (instancetype)initWith:(NSTextCheckingResult *)match source:(NSString *)source;
+ (instancetype)matchWith:(NSTextCheckingResult *)match source:(NSString *)source;

- (NSString *)group:(NSUInteger)index;
- (NSRange)range:(NSUInteger)index;
- (NSArray *)allGroups;
- (NSArray *)allGroups:(NSString *)defaultVal;

@end

@interface Regex : NSObject

@property (nonatomic, strong) NSArray *matches;
@property (nonatomic, strong) NSRegularExpression *regex;
@property (nonatomic, retain) NSString *source;
@property (nonatomic) NSMatchingOptions matchingOptions;

- (instancetype)initWithPattern:(NSString *)pattern
                        options:(NSRegularExpressionOptions)options
                          error:(NSError *__autoreleasing *)error;

+ (instancetype)regex:(NSString *)pattern;
+ (instancetype)regex:(NSString *)pattern options:(NSRegularExpressionOptions)options;
+ (instancetype)regex:(NSString *)pattern error:(NSError *__autoreleasing *)error;
+ (instancetype)regex:(NSString *)pattern
              options:(NSRegularExpressionOptions)options
                error:(NSError *__autoreleasing *)error;

- (RegexMatch *)matchOne:(NSString *)source;
- (NSArray *)matchAll:(NSString *)source;
- (RegexMatch *)matchOne:(NSString *)source options:(NSMatchingOptions)options;
- (NSArray *)matchAll:(NSString *)source options:(NSMatchingOptions)options;

- (NSString *)replace:(NSString *)source template:(NSString *)template;
- (NSString *)replace:(NSString *)source template:(NSString *)template options:(NSMatchingOptions)options;

@end
