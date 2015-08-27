//
//  StoryFormat.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Story;

@interface StoryFormat : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, getter=isUserAdded) BOOL userAdded;
@property (nonatomic, getter=isLoaded) BOOL loaded;
@property (nonatomic, readonly) NSDictionary *properties;
@property (nonatomic, copy) NSURL *imageUrl;
@property (nonatomic, readonly) BOOL isProofing;

- (id)initWithName:(NSString *)name
               url:(NSURL *)url
          imageUrl:(NSURL *)imageUrl
         userAdded:(BOOL)userAdded;
- (void)load:(void (^)(StoryFormat *storyFormat))completionHandler
       error:(void (^)(NSError *error))errorHandler;
- (NSString *)publishStory:(Story *)story
                   startId:(NSInteger)startId
                   options:(NSArray *)options
                     error:(NSError **)error;
- (void)publishStory:(Story *)story
             startId:(NSInteger)startId
             options:(NSArray *)options
           createZip:(BOOL)createZip
          completion:(void (^)(Story *story, NSString *path))completionHandler
               error:(void (^)(NSError *error))errorHandler;
- (void)publishStory:(Story *)story
                path:(NSString *)path
             startId:(NSInteger)startId
             options:(NSArray *)options
           createZip:(BOOL)createZip
          completion:(void (^)(Story *story, NSString *path))completionHandler
               error:(void (^)(NSError *error))errorHandler;
- (void)saveToLocalPath:(NSString *)path
             completion:(void (^)(StoryFormat *storyFormat))completionHandler
                  error:(void (^)(NSError *error))errorHandler;

@end
