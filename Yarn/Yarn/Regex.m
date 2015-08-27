//
//  Regex.m
//  Yarn
//
//  Created by Mark Jundo Documento on 2/10/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import "NSString+TestNonEmpty.h"
#import "Regex.h"

@implementation RegexMatch

- (instancetype)initWith:(NSTextCheckingResult *)match source:(NSString *)source {
    self = [super init];
    if (self) {
        _source = source;
        NSMutableArray *groups = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
        for (NSUInteger i = 0; i < match.numberOfRanges; i++) {
            [groups addObject:[NSValue valueWithRange:[match rangeAtIndex:i]]];
        }
        _groups = [NSArray arrayWithArray:groups];
    }
    return self;
}

+ (instancetype)matchWith:(NSTextCheckingResult *)match source:(NSString *)source {
    return [[RegexMatch alloc] initWith:match source:source];
}

- (NSString *)group:(NSUInteger)index {
    if (index < [_groups count]) {
        NSRange range = [[self.groups objectAtIndex:index] rangeValue];
        if (range.location == NSNotFound) {
            return nil;
        }
        return [_source substringWithRange:range];
    }
    
    return nil;
}

- (NSRange)range:(NSUInteger)index {
    if (index < [_groups count]) {
        return [[_groups objectAtIndex:index] rangeValue];
    }
    
    return NSMakeRange(NSNotFound, 0);
}

- (NSUInteger)getCount {
    return [_groups count];
}

- (NSArray *)allGroups:(NSString *)defaultVal {
    NSMutableArray *groups = [NSMutableArray arrayWithCapacity:[_groups count] - 1];
    for (NSValue *v in _groups) {
        if (v != [_groups firstObject]) {
            NSRange range = [v rangeValue];
            if (range.location == NSNotFound) {
                NSAssert(defaultVal != nil, @"defaultVal should not be nil");
                [groups addObject:defaultVal];
            }
            else {
                [groups addObject:[_source substringWithRange:range]];
            }
        }
    }
    return [NSArray arrayWithArray:groups];
}

@end

@implementation Regex

- (instancetype)initWithPattern:(NSString *)pattern
                        options:(NSRegularExpressionOptions)options
                          error:(NSError *__autoreleasing *)error {
    self = [super init];
    if (self) {
        _regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:error];
        _matchingOptions = 0;
    }
    
    return self;
}

+ (instancetype)regex:(NSString *)pattern {
    NSError *error = nil;
    return [Regex regex:pattern options:0 error:&error];
}

+ (instancetype)regex:(NSString *)pattern options:(NSRegularExpressionOptions)options {
    NSError *error = nil;
    return [Regex regex:pattern options:options error:&error];
}

+ (instancetype)regex:(NSString *)pattern error:(NSError *__autoreleasing *)error {
    return [Regex regex:pattern options:0 error:error];
}

+ (instancetype)regex:(NSString *)pattern options:(NSRegularExpressionOptions)options error:(NSError *__autoreleasing *)error {
    Regex *re = [[Regex alloc] initWithPattern:pattern options:options error:error];
    if (*error) {
        return nil;
    }
    return re;
}

- (RegexMatch *)matchOne:(NSString *)source {
    return [self matchOne:source options:NSMatchingWithoutAnchoringBounds];
}

- (NSArray *)matchAll:(NSString *)source {
    return [self matchAll:source options:NSMatchingWithoutAnchoringBounds];
}

- (RegexMatch *)matchOne:(NSString *)source options:(NSMatchingOptions)options {
    [self _updateMatchesIn:source options:options];
    return [_matches firstObject];
}

- (NSArray *)matchAll:(NSString *)source options:(NSMatchingOptions)options {
    [self _updateMatchesIn:source options:options];
    return _matches;
}

- (NSString *)replace:(NSString *)source template:(NSString *)template {
    return [_regex stringByReplacingMatchesInString:source
                                            options:NSMatchingWithoutAnchoringBounds
                                              range:NSMakeRange(0, [source length])
                                       withTemplate:template];
}

- (NSString *)replace:(NSString *)source template:(NSString *)template options:(NSMatchingOptions)options {
    return [_regex stringByReplacingMatchesInString:source
                                            options:options
                                              range:NSMakeRange(0, [source length])
                                       withTemplate:template];
}

- (void)_updateMatchesIn:(NSString *)source options:(NSMatchingOptions)options {
    if (!_matches ||
        ![_source isEqualToString:source] ||
        _matchingOptions != options) {
        NSArray *results = [_regex matchesInString:source
                                           options:options
                                             range:NSMakeRange(0, [source length])];
        _source = source;
        _matchingOptions = options;
        NSMutableArray *matches = [NSMutableArray arrayWithCapacity:results.count];
        for (NSTextCheckingResult *result in results) {
            [matches addObject:[RegexMatch matchWith:result source:source]];
        }
        _matches = [NSArray arrayWithArray:matches];
    }
}

@end
