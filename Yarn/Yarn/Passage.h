//
//  Passage.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Story;

@interface Passage : NSObject

@property (nonatomic) NSInteger Id;
@property (nonatomic, weak) Story *story;
@property (nonatomic) double top;
@property (nonatomic) double left;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSArray *tags;

- (instancetype)initWithStory:(Story *)story;
- (instancetype)initWithStory:(Story *)story Id:(NSInteger)Id;

+ (instancetype)passageInStory:(Story *)story;
+ (instancetype)passageInStory:(Story *)story named:(NSString *)name;
+ (instancetype)passageInStory:(Story *)story Id:(NSInteger)Id named:(NSString *)name text:(NSString *)text tags:(NSArray *)tags;

- (NSString *)excerpt;
- (NSArray *)links:(BOOL)internalOnly;
- (NSString *)publish:(NSInteger)Id;
- (NSString *)validate;

@end
