//
//  Story.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "Constants.h"
#import "Passage.h"
#import "Regex.h"
#import "SSZipArchive.h"
#import "Story.h"
#import "Utils.h"

typedef void (^StoryCompletionBlock)(Story *story);

@interface Story() {
    NSMutableArray *_elementStack;
    NSInteger _passageId;
    Passage *_currentPassage;
    NSMutableDictionary *_passages;
    NSInteger _startId;
    
    StoryCompletionBlock _completionHandler;
    ErrorBlock _errorHandler;
}

@end

@implementation Story

static NSString *_template = @"<tw-storydata name=\"%@\" startnode=\"%@\" creator=\"%@\" creator-version=\"%@\" ifid=\"%@\" format=\"%@\" options=\"%@\"><style role=\"stylesheet\" id=\"twine-user-stylesheet\" type=\"text/twine-css\">%@</style><script role=\"script\" id=\"twine-user-script\" type=\"text/twine-javascript\">%@</script>%@</tw-storydata>";

@synthesize passages = _passages;

- (id)init {
    self = [super init];
    if (self) {
        _name = nil;
        _startPassage = nil;
        _script = nil;
        _stylesheet = nil;
        _storyFormat = nil;
        _lastUpdate = nil;
        _ifId = nil;
        _passages = nil;
        _path = nil;
        
        _currentPassage = nil;
        _elementStack = nil;
        _passageId = 0;
    }
    
    return self;
}

- (id)initWithDefaults {
    self = [super init];
    if (self) {
        _name = @"Untitled Story";
        _script = @"";
        _stylesheet = @"";
        _storyFormat = @"Harlowe";
        _lastUpdate = [NSDate date];
        _ifId = [[[NSUUID UUID] UUIDString] uppercaseString];
        _passages = [NSMutableDictionary dictionary];
        _path = nil;
        
        _startPassage = [[self createNewPassage:nil] name];
        _currentPassage = nil;
        _elementStack = nil;
        _passageId = 0;
    }
    
    return self;
}

- (void)archiveToPath:(NSString *)path
           completion:(void (^)(Story *story, NSString *zipPath))completionHandler
                error:(void (^)(NSError *error))errorHandler {
    [self _saveToPath:path createZip:YES completion:completionHandler error:errorHandler];
}

- (void)changePassageName:(Passage *)passage
                  newName:(NSString *)newName {
    if (![[passage name] isEqualToString:newName]) {
        [_passages setObject:passage forKey:newName];
        [_passages removeObjectForKey:[passage name]];
        if ([[passage name] isEqualToString:_startPassage]) {
            _startPassage = newName;
        }
        [passage setName:newName];
    }
}

- (Passage *)createNewPassage:(NSError **)error {
    return [self createNewPassage:nil error:error];
}

- (Passage *)createNewPassage:(NSString *)name error:(NSError **)error {
    Passage *passage = (name ? [Passage passageInStory:self named:name]:
                        [Passage passageInStory:self]);
    NSString *errMsg = [passage validate];
    if ([errMsg notEmpty]) {
        if (error) {
            *error = [NSError errorWithDomain:@"Story"
                                         code:kDuplicatePassageName
                                     userInfo:@{NSLocalizedDescriptionKey:errMsg}];
        }
        return nil;
    }
    else {
        [_passages setObject:passage forKey:[passage name]];
        return passage;
    }
}

- (void)deletePassage:(Passage *)passage {
    [_passages removeObjectForKey:[passage name]];
}

- (void)deleteSaved:(void (^)(Story *story))completionHandler
              error:(void (^)(NSError *error))errorHandler {
    DISPATCH_ASYNC(^{
        NSError *error = nil;
        if (![[_path lastPathComponent] isEqualToString:_ifId]) {
            error = [NSError errorWithDomain:@"Story" code:kInvalidPath userInfo:@{NSLocalizedDescriptionKey:_LS(@"Story path is invalid.")}];
            if (errorHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    errorHandler(error);
                });
            }
            return;
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:_path error:&error];
        if (error) {
            if (errorHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    errorHandler(error);
                });
            }
        }
        else {
            if (completionHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    completionHandler(self);
                });
            }
        }
    });
}

- (Passage *)getPassageWithId:(NSInteger)Id {
    for (Passage *passage in [_passages allValues]) {
        if ([passage Id] == Id) {
            return passage;
        }
    }
    
    return nil;
}

- (Passage *)getPassageWithName:(NSString *)name {
    return [_passages objectForKey:name];
}

- (void)load:(void (^)(Story *story))completionHandler error:(void (^)(NSError *error))errorHandler {
    DispatchAsync(^{
        NSError *error = nil;
        if (!_path) {
            error = [NSError errorWithDomain:@"Story" code:kNoPath userInfo:@{NSLocalizedDescriptionKey:_LS(@"No path to load from")}];
            if (errorHandler) {
                errorHandler(error);
            }
            return;
        }
        
        NSString *path = [_path stringByAppendingPathComponent:@"story.html"];
        NSLog(@"Reading %@", path);
        NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            if (errorHandler) {
                errorHandler(error);
            }
            return;
        }
        
        Regex *regex = [Regex regex:@"<tw-storydata.*?</tw-storydata>"
                            options:NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionUseUnixLineSeparators];
        NSString *storyData = [[regex matchOne:contents] group:0];
        if (!storyData) {
            if (errorHandler) {
                error = [NSError errorWithDomain:@"Story" code:kInvalidTwine2File userInfo:@{NSLocalizedDescriptionKey:_LS(@"File is not in Twine 2 format.")}];
                DispatchAsyncMain(^{
                    errorHandler(error);
                });
            }
            return;
        }
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[storyData dataUsingEncoding:NSUTF8StringEncoding]];
        [parser setDelegate:self];
        _elementStack = [NSMutableArray array];
        _passageId = 0;
        _completionHandler = completionHandler;
        _errorHandler = errorHandler;
        [parser parse];
    });
}

+ (Story *)loadInfo:(NSString *)path error:(NSError **)error {
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        if (!isDir) {
            *error = [NSError errorWithDomain:@"Story" code:kInvalidPath userInfo:@{NSLocalizedDescriptionKey:_LS(@"Story path is invalid.")}];
            return nil;
        }
    }
    NSString *_path = [path stringByAppendingPathComponent:@"info.txt"];
    NSError *_error = nil;
    NSString* contents = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:&_error];
    if (_error) {
        *error = _error;
        return nil;
    }
    NSArray *data = [contents componentsSeparatedByString:@"\n"];
    Story *story = [[Story alloc] init];
    [story setName:[data objectAtIndex:0]];
    [story setLastUpdate:[[[NSFileManager defaultManager]
                           attributesOfItemAtPath:_path
                           error:error]
                          valueForKey:NSFileModificationDate]];
    [story setIfId:[path lastPathComponent]];
    [story setPath:path];
    
    return story;
}

- (NSInteger)nextId {
    return ++_passageId;
}

- (NSArray *)passagesSortedByName {
    return [[_passages allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Passage *a = obj1, *b = obj2;
        return [[a name] compare:[b name]];
    }];
}

- (NSArray *)passagesSortedById {
    return [[_passages allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Passage *a = obj1, *b = obj2;
        return [[NSNumber numberWithInteger:[a Id]] compare:[NSNumber numberWithInteger:[b Id]]];
    }];
}

- (NSString *)publishWithStartId:(NSInteger)startId
                 startIsOptional:(BOOL)startIsOptional
                         options:(NSArray *)options
                           error:(NSError **)error {
    Passage *startPassage = [self getPassageWithName:_startPassage];
    NSInteger startDbId = startId < 1 ? (startPassage ? [startPassage Id]:-1):startId;
    
    if (!startIsOptional) {
        if (startDbId < 1) {
            if (error) {
                *error = [NSError errorWithDomain:@"Story" code:kNoStartingPoint userInfo:@{NSLocalizedDescriptionKey:_LS(@"There is no starting point set for this story.")}];
            }
            return nil;
        }
        else if (![self getPassageWithId:startDbId]) {
            if (error) {
                *error = [NSError errorWithDomain:@"Story" code:kStartingPointNonExistent userInfo:@{NSLocalizedDescriptionKey:_LS(@"The passage set as starting point for this story does not exist.")}];
            }
            return nil;
        }
    }
    
    NSString *passageData = @"";
    int index = 0;
    for (Passage *passage in [self passagesSortedById]) {
        passageData = [passageData stringByAppendingString:[passage publish:index + 1]];
        if ([passage Id] == startDbId) {
            startId = index + 1;
        }
        ++index;
    }
    
    NSString *optStr = [options count] ? [options componentsJoinedByString:@" "]:@"";
    
    return [NSString stringWithFormat:_template,
            _name,
            startId > 0 ? [@(startId) stringValue]:@"",
            AppName(),
            AppVersion(),
            _ifId,
            _storyFormat,
            optStr,
            _stylesheet,
            _script,
            passageData];
}

- (void)save:(void (^)(Story *story))completionHandler
       error:(void (^)(NSError *error))errorHandler {
    [self
     saveAndCreateZip:NO
     completion:^(Story *story, NSString *zipPath) {
         completionHandler(story);
     }
     error:errorHandler];
}

- (void)saveAndCreateZip:(BOOL)createZip
              completion:(void (^)(Story *story, NSString *zipPath))completionHandler
                   error:(void (^)(NSError *error))errorHandler {
    [self _saveToPath:nil
            createZip:createZip
           completion:completionHandler
                error:errorHandler];
}

- (void)saveToPath:(NSString *)path
        completion:(void (^)(Story *story))completionHandler
             error:(void (^)(NSError *error))errorHandler {
    [self
     saveToPath:path
     createZip:NO
     completion:^(Story *story, NSString *zipPath) {
         completionHandler(story);
     }
     error:errorHandler];
}

- (void)saveToPath:(NSString *)path
         createZip:(BOOL)createZip
        completion:(void (^)(Story *story, NSString *zipPath))completionHandler
             error:(void (^)(NSError *error))errorHandler {
    [self _saveToPath:path
            createZip:createZip
           completion:completionHandler
                error:errorHandler];
}

- (void)_saveToPath:(NSString *)pathOrNil
          createZip:(BOOL)createZip
         completion:(void (^)(Story *story, NSString *zipPath))completionHandler
              error:(void (^)(NSError *error))errorHandler {
    DISPATCH_ASYNC(^{
        NSString *path = pathOrNil;
        NSFileManager *manager = [NSFileManager defaultManager];
        if (!pathOrNil) {
            NSAssert(_path != nil, @"Save path must be provided for saving.");
            path = _path;
        }
        else {
            path = [pathOrNil stringByAppendingPathComponent:_ifId];
            if (![manager fileExistsAtPath:path]) {
                NSError *error = nil;
                [manager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
                if (error) {
                    if (errorHandler) {
                        DISPATCH_ASYNC_MAIN(^{
                            errorHandler(error);
                        });
                    }
                    return;
                }
            }
            _path = path;
        }
        
        NSString *mediaPath = [path stringByAppendingPathComponent:@"images"];
        if (![manager fileExistsAtPath:mediaPath]) {
            NSError *error = nil;
            [manager createDirectoryAtPath:mediaPath withIntermediateDirectories:NO attributes:nil error:&error];
            if (error) {
                if (errorHandler) {
                    DISPATCH_ASYNC_MAIN(^{
                        errorHandler(error);
                    });
                }
                return;
            }
        }
        
        mediaPath = [path stringByAppendingPathComponent:@"audio"];
        if (![manager fileExistsAtPath:mediaPath]) {
            NSError *error = nil;
            [manager createDirectoryAtPath:mediaPath withIntermediateDirectories:NO attributes:nil error:&error];
            if (error) {
                if (errorHandler) {
                    DISPATCH_ASYNC_MAIN(^{
                        errorHandler(error);
                    });
                }
                return;
            }
        }
        
        mediaPath = [path stringByAppendingPathComponent:@"movies"];
        if (![manager fileExistsAtPath:mediaPath]) {
            NSError *error = nil;
            [manager createDirectoryAtPath:mediaPath withIntermediateDirectories:NO attributes:nil error:&error];
            if (error) {
                DISPATCH_ASYNC_MAIN(^{
                    errorHandler(error);
                });
                return;
            }
        }
        
        NSString *fpath = [path stringByAppendingPathComponent:@"story.html"];
        NSError *error = nil;
        NSString *published = [self publishWithStartId:-1 startIsOptional:YES options:@[] error:&error];
        if (error) {
            DISPATCH_ASYNC_MAIN(^{
                errorHandler(error);
            });
            return;
        }
        NSLog(@"%@", published);
        [published writeToFile:fpath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            DISPATCH_ASYNC_MAIN(^{
                errorHandler(error);
            });
            return;
        }
        fpath = [path stringByAppendingPathComponent:@"info.txt"];
        [_name writeToFile:fpath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            DISPATCH_ASYNC_MAIN(^{
                errorHandler(error);
            });
            return;
        }
        
        if (createZip) {
            NSString *fname =
            [_name stringByReplacingOccurrencesOfString:@"[^a-zA-Z0-9_\\- ]"
                                             withString:@""
                                                options:NSRegularExpressionSearch
                                                  range:NSMakeRange(0, [_name length])];
            fname = [fname stringByReplacingOccurrencesOfString:@" " withString:@"-"];
            fname = [fname stringByAppendingFormat:@"-%@", _ifId];
            fname = [fname stringByAppendingPathExtension:@"export"];
            fname = [fname stringByAppendingPathExtension:@"story"];
            fname = [fname stringByAppendingPathExtension:@"zip"];
            NSString *zpath = [path stringByAppendingPathComponent:fname];
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
            if (![zipper writeFileAtPath:[path stringByAppendingPathComponent:@"story.html"] withFileName:@"story.html"]) {
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
            if (completionHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    completionHandler(self, zpath);
                });
            }
        }
        else {
            if (completionHandler) {
                DISPATCH_ASYNC_MAIN(^{
                    completionHandler(self, nil);
                });
            }
        }
        
    });
}

#pragma mark NSXMLParserDelegate
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    NSLog(@"Start: %@", elementName);
    [_elementStack addObject:elementName];
    if ([elementName isEqualToString:@"tw-storydata"]) {
        _name = [attributeDict valueForKey:@"name"];
        _storyFormat = [attributeDict valueForKey:@"format"];
        NSLog(@"Creator: %@", [attributeDict valueForKey:@"creator"]);
        NSLog(@"Version: %@", [attributeDict valueForKey:@"creator-version"]);
        if ([[attributeDict valueForKey:@"ifid"] notEmpty]) {
            _ifId = [attributeDict valueForKey:@"ifid"];
        }
        NSLog(@"IFId: %@", [attributeDict valueForKey:@"ifid"]);
        NSLog(@"Options: %@", [attributeDict valueForKey:@"options"]);
        NSString *startNode = [attributeDict valueForKey:@"startnode"];
        _startId = [startNode notEmpty] ? [startNode integerValue]:-1;
        _passages = [NSMutableDictionary dictionary];
        _stylesheet = @"";
        _script = @"";
    }
    else if ([elementName isEqualToString:@"tw-passagedata"]) {
        _currentPassage = [Passage passageInStory:self
                                               Id:[[attributeDict valueForKey:@"pid"] integerValue]
                                            named:[attributeDict valueForKey:@"name"]
                                             text:@""
                                             tags:[[attributeDict valueForKey:@"tags"] componentsSeparatedByString:@" "]];
        NSArray *pos = [[attributeDict valueForKey:@"position"] componentsSeparatedByString:@","];
        [_currentPassage setLeft:[[pos objectAtIndex:0] floatValue]];
        [_currentPassage setTop:[[pos objectAtIndex:1] floatValue]];
        if ([_currentPassage Id] == _startId) {
            _startPassage = [_currentPassage name];
        }
        NSLog(@"%@ - %d", [_currentPassage name], (int)[_currentPassage Id]);
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSLog(@"End: %@", elementName);
    while ([_elementStack count] && ![[_elementStack lastObject] isEqualToString:elementName]) {
        [_elementStack removeLastObject];
    }
    [_elementStack removeLastObject];
    if ([elementName isEqualToString:@"tw-passagedata"]) {
        [_passages setObject:_currentPassage forKey:[_currentPassage name]];
        if (_passageId < [_currentPassage Id]) {
            _passageId = [_currentPassage Id];
        }
        _currentPassage = nil;
    }
    else if ([elementName isEqualToString:@"tw-storydata"]) {
        if (_completionHandler) {
            DISPATCH_ASYNC_MAIN(^{
                _completionHandler(self);
            });
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    if ([[_elementStack lastObject] isEqualToString:@"script"]) {
        _script = [CDATABlock UTF8String];
    }
    else if ([[_elementStack lastObject] isEqualToString:@"stylesheet"]) {
        _stylesheet = [CDATABlock UTF8String];
    }
    else if ([[_elementStack lastObject] isEqualToString:@"tw-passagedata"]) {
        [_currentPassage setText:[CDATABlock UTF8String]];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ([[_elementStack lastObject] isEqualToString:@"script"]) {
        _script = [_script stringByAppendingString:string];
    }
    else if ([[_elementStack lastObject] isEqualToString:@"stylesheet"]) {
        _stylesheet = [_stylesheet stringByAppendingString:string];
    }
    else if ([[_elementStack lastObject] isEqualToString:@"tw-passagedata"]) {
        [_currentPassage setText:[[_currentPassage text] stringByAppendingString:string]];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"Parse error: %@", parseError);
    [parser abortParsing];
    if (_errorHandler) {
        DISPATCH_ASYNC_MAIN(^{
            _errorHandler(parseError);
        });
    }
}

@end
