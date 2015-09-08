//
//  Story.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Passage;

@interface Story : NSObject <NSXMLParserDelegate>

@property (nonatomic, copy) NSString *ifId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *startPassage;
@property (nonatomic, copy) NSString *script;
@property (nonatomic, copy) NSString *stylesheet;
@property (nonatomic, copy) NSString *storyFormat;
@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, readonly) NSDictionary *passages;
@property (nonatomic, copy) NSString *path;

- (instancetype)initWithDefaults;

- (void)archiveToPath:(NSString *)path
           completion:(void (^)(Story *story, NSString *zipPath))completionHandler
                error:(void (^)(NSError *error))errorHandler;
- (void)changePassageName:(Passage *)passage
                  newName:(NSString *)newName;
- (Passage *)createNewPassage:(NSError **)error;
- (Passage *)createNewPassage:(NSString *)name error:(NSError **)error;
- (void)deletePassage:(Passage *)passage;
- (void)deleteSaved:(void (^)(Story *story))completionHandler
              error:(void (^)(NSError *error))errorHandler;
- (Passage *)getPassageWithId:(NSInteger)Id;
- (Passage *)getPassageWithName:(NSString *)name;
- (void)load:(void (^)(Story *story))completionHandler
       error:(void (^)(NSError *error))errorHandler;
+ (Story *)loadInfo:(NSString *)path error:(NSError **)error;
+ (void)loadTweeFromPath:(NSString *)path
               imageData:(void (^)(NSData *imageData, NSString *filename))imageDataHandler
              completion:(void (^)(Story *story))completionHandler
                   error:(void (^)(NSError *error))errorHandler;
- (NSInteger)nextId;
- (NSString *)publishWithStartId:(NSInteger)startId
                 startIsOptional:(BOOL)startIsOptional
                         options:(NSArray *)options
                           error:(NSError **)error;
- (void)save:(void (^)(Story *story))completionHandler
       error:(void (^)(NSError *error))errorHandler;
- (void)saveAndCreateZip:(BOOL)createZip
              completion:(void (^)(Story *story, NSString *zipPath))completionHandler
                   error:(void (^)(NSError *error))errorHandler;
- (void)saveToPath:(NSString *)path
        completion:(void (^)(Story *story))completionHandler
             error:(void (^)(NSError *error))errorHandler;
- (void)saveToPath:(NSString *)path
         createZip:(BOOL)createZip
        completion:(void (^)(Story *story, NSString *zipPath))completionHandler
             error:(void (^)(NSError *error))errorHandler;

@end
