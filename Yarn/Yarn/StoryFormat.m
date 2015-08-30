//
//  StoryFormat.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "Constants.h"
#import "NSData+UTF8String.h"
#import "SSZipArchive.h"
#import "Story.h"
#import "StoryFormat.h"
#import "Utils.h"

typedef void (^StoryFormatCompletionBlock)(StoryFormat *storyFormat);

@interface StoryFormat() {
    NSMutableDictionary *_properties;
}

@property (nonatomic, strong) NSURLRequest *request;

@end

@implementation StoryFormat

@synthesize properties = _properties;

- (id)init {
    self = [super init];
    if (self) {
        _name = @"Untitled Story Format";
        _url = nil;
        _userAdded = YES;
        _loaded = NO;
        _properties = nil;
    }
    
    return self;
}

- (id)initWithName:(NSString *)name url:(NSURL *)url imageUrl:(NSURL *)imageUrl userAdded:(BOOL)userAdded {
    self = [super init];
    if (self) {
        _name = name;
        _url = url;
        _imageUrl = imageUrl;
        _userAdded = userAdded;
        _loaded = NO;
        _properties = nil;
    }
    
    return self;
}

- (BOOL)isProofing {
    return [[_properties valueForKey:@"proofing"] boolValue];
}

- (void)load:(void (^)(StoryFormat *storyFormat))completionHandler
       error:(void (^)(NSError *error))errorHandler {
    if (!_loaded) {
        _request = [NSURLRequest requestWithURL:_url
                                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                                timeoutInterval:10.0];
        
        [NSURLConnection sendAsynchronousRequest:_request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if (error) {
                                       if (errorHandler) {
                                           errorHandler(error);
                                       }
                                   }
                                   else {
                                       NSError *jerror = nil;
                                       NSString *str = [data UTF8String];
                                       str = [str stringByReplacingOccurrencesOfString:@"^\\s*window\\.storyFormat\\("
                                                                            withString:@""
                                                                               options:NSRegularExpressionSearch
                                                                                 range:NSMakeRange(0, [str length])];
                                       str = [str stringByReplacingOccurrencesOfString:@"\\);*\\s*$"
                                                                            withString:@""
                                                                               options:NSRegularExpressionSearch
                                                                                 range:NSMakeRange(0, [str length])];
                                       _properties = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                                                                     options:kNilOptions
                                                                                       error:&jerror];
                                       
                                       if (jerror) {
                                           if (errorHandler) {
                                               errorHandler(jerror);
                                           }
                                       }
                                       else {
                                           _name = [_properties objectForKey:@"name"];
                                           _loaded = YES;
                                           if (completionHandler) {
                                               completionHandler(self);
                                           }
                                       }
                                   }
                               }];
    }
    else {
        completionHandler(self);
    }
}

- (NSString *)publishStory:(Story *)story
                   startId:(NSInteger)startId
                   options:(NSArray *)options
                     error:(NSError **)error {
    NSString *output = [_properties objectForKey:@"source"];
    
    output = [output stringByReplacingOccurrencesOfString:@"{{STORY_NAME}}"
                                               withString:[story name]
                                                  options:NSCaseInsensitiveSearch
                                                    range:NSMakeRange(0, [output length])];
    
    NSError *_error = nil;
    NSString *publishedContent = [story publishWithStartId:startId startIsOptional:[self isProofing] options:options error:&_error];
    if (_error) {
        *error = _error;
        return nil;
    }
    output = [output stringByReplacingOccurrencesOfString:@"{{STORY_DATA}}"
                                               withString:publishedContent
                                                  options:NSCaseInsensitiveSearch
                                                    range:NSMakeRange(0, [output length])];
    
    return output;
}

- (void)publishStory:(Story *)story
             startId:(NSInteger)startId
             options:(NSArray *)options
           createZip:(BOOL)createZip
          completion:(void (^)(Story *story, NSString *path))completionHandler
               error:(void (^)(NSError *error))errorHandler {
    [self publishStory:story
                  path:nil
               startId:startId
               options:options
             createZip:createZip
            completion:completionHandler
                 error:errorHandler];
}

- (void)publishStory:(Story *)story
                path:(__nullable NSString *)path
             startId:(NSInteger)startId
             options:(NSArray *)options
           createZip:(BOOL)createZip
          completion:(void (^)(Story *story, NSString *path))completionHandler
               error:(void (^)(NSError *error))errorHandler {
    if (![self isLoaded]) {
        [self
         load:^(StoryFormat *storyFormat) {
             NSError *error = nil;
             NSString *output = [self publishStory:story
                                           startId:startId
                                           options:options
                                             error:&error];
             if (error) {
                 if (errorHandler) {
                     errorHandler(error);
                 }
             }
             else {
                 [self _saveStory:story
                             path:path
                           output:output
                        createZip:createZip
                       completion:completionHandler
                            error:errorHandler];
             }
         }
         error:^(NSError *error) {
             if (errorHandler) {
                 errorHandler(error);
             }
             return;
         }];
    }
    else {
        NSError *error = nil;
        NSString *output = [self publishStory:story
                                      startId:startId
                                      options:options
                                        error:&error];
        if (error) {
            if (errorHandler) {
                errorHandler(error);
            }
        }
        else {
            [self _saveStory:story
                        path:path
                      output:output
                   createZip:createZip
                  completion:completionHandler
                       error:errorHandler];
        }
    }
}

- (void)_saveStory:(Story*)story
              path:(NSString *)pathOrNil
            output:(NSString *)output
         createZip:(BOOL)createZip
        completion:(void (^)(Story *story, NSString *path))completionHandler
             error:(void (^)(NSError *error))errorHandler {
    DISPATCH_ASYNC(^{
        NSString *path = pathOrNil;
        NSFileManager *manager = [NSFileManager defaultManager];
        if (!path) {
            NSString *buildDir = [[story path] stringByAppendingPathComponent:@"build"];
            NSError *error = nil;
            if (![manager fileExistsAtPath:buildDir]) {
                [manager createDirectoryAtPath:buildDir withIntermediateDirectories:NO attributes:nil error:&error];
                if (error) {
                    if (errorHandler) {
                        DISPATCH_ASYNC_MAIN(^{
                            errorHandler(error);
                        });
                    }
                    return;
                }
            }
            path = [buildDir stringByAppendingPathComponent:[self isProofing] ? @"proof.html":@"game.html"];
        }
        
        NSError *error = nil;
        [output writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            if (errorHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    errorHandler(error);
                });
            }
            return;
        }
        
        NSString *symlinkPath = nil;
        if (![self isProofing]) {
            symlinkPath = [[story path] stringByAppendingPathComponent:@"game.html"];
            [manager removeItemAtPath:symlinkPath error:nil];
            [manager createSymbolicLinkAtPath:symlinkPath withDestinationPath:path error:&error];
            if (error) {
                NSLog(@"%@", [error localizedDescription]);
                symlinkPath = nil;
            }
        }
        
        if (createZip) {
            NSString *fname =
            [[story name] stringByReplacingOccurrencesOfString:@"[^a-zA-Z0-9_\\- ]"
                                             withString:@""
                                                options:NSRegularExpressionSearch
                                                  range:NSMakeRange(0, [[story name] length])];
            fname = [fname stringByAppendingFormat:@"-%@", [story ifId]];
            fname = [fname stringByAppendingPathExtension:@"export"];
            fname = [fname stringByAppendingPathExtension:@"zip"];
            NSString *zpath = [[path stringByDeletingLastPathComponent]
                               stringByAppendingPathComponent:fname];
            NSLog(@"Creating zip archive at %@", zpath);
            SSZipArchive *zipper = [[SSZipArchive alloc] initWithPath:zpath];
            if (![zipper open]) {
                if (errorHandler) {
                    error = [NSError errorWithDomain:@"Story"
                                                code:kCantOpenArchive
                                            userInfo:@{NSLocalizedDescriptionKey:_LS(@"Unable to create archive file.")}];
                    DISPATCH_ASYNC_MAIN(^{
                        errorHandler(error);
                    });
                }
                return;
            }
            if (![zipper writeFileAtPath:path withFileName:@"story.html"]) {
                if (errorHandler) {
                    error = [NSError errorWithDomain:@"Story"
                                                code:kCantWriteToArchive
                                            userInfo:@{NSLocalizedDescriptionKey:_LS(@"Unable to write file to archive.")}];
                    DISPATCH_ASYNC_MAIN(^{
                        errorHandler(error);
                    });
                }
                return;
            }
            NSString *mediaPath = [path stringByAppendingPathComponent:@"images"];
            NSArray *images = [manager contentsOfDirectoryAtPath:mediaPath error:&error];
            if (error) {
                NSLog(@"%@", [error localizedDescription]);
            }
            else {
                for (NSString *imagePath in images) {
                    NSLog(@"Archiving %@", imagePath);
                    if (![zipper writeFileAtPath:[mediaPath stringByAppendingPathComponent:imagePath]
                                    withFileName:[[mediaPath lastPathComponent]
                                                  stringByAppendingPathComponent:imagePath]]) {
                                        if (errorHandler) {
                                            error = [NSError errorWithDomain:@"Story"
                                                                        code:kCantWriteToArchive
                                                                    userInfo:@{NSLocalizedDescriptionKey:_LS(@"Unable to write file to archive.")}];
                                            DISPATCH_ASYNC_MAIN(^{
                                                errorHandler(error);
                                            });
                                        }
                                        return;
                                    }
                }
            }
            if (![zipper close]) {
                if (errorHandler) {
                    error = [NSError errorWithDomain:@"Story"
                                                code:kCantCloseArchive
                                            userInfo:@{NSLocalizedDescriptionKey:_LS(@"Unable to close archive file.")}];
                    DISPATCH_ASYNC_MAIN(^{
                        errorHandler(error);
                    });
                }
                return;
            }
            path = zpath;
        }
        else if (symlinkPath) {
            path = symlinkPath;
        }
        
        if (completionHandler) {
            DISPATCH_ASYNC_MAIN(^{
                completionHandler(story, path);
            });
        }
    });
}

- (void)saveToLocalPath:(NSString *)path
             completion:(void (^)(StoryFormat *storyFormat))completionHandler
                  error:(void (^)(NSError *error))errorHandler {
    DISPATCH_ASYNC(^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSString *_path = [_name stringByReplacingOccurrencesOfString:@"[^a-zA-Z0-9_\\- ]"
                                                           withString:@""
                                                              options:NSRegularExpressionSearch range:NSMakeRange(0, [_name length])];
        _path = [path stringByAppendingPathComponent:_path];
        NSError *error = nil;
        if ([manager fileExistsAtPath:_path]) {
            [manager removeItemAtPath:_path error:&error];
            if (error) {
                if (errorHandler) {
                    DISPATCH_ASYNC_MAIN(^{
                        errorHandler(error);
                    });
                }
                return;
            }
        }
        [manager createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            if (errorHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    errorHandler(error);
                });
            }
            return;
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:_properties options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            if (errorHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    errorHandler(error);
                });
            }
            return;
        }
        [[data UTF8String] writeToFile:[_path stringByAppendingPathComponent:@"format.js"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            if (errorHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    errorHandler(error);
                });
            }
            return;
        }
        if (completionHandler) {
            DISPATCH_ASYNC_MAIN(^{
                completionHandler(self);
            });
        }
    });
}

@end
