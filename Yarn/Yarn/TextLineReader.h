//
//  TextLineReader.h
//  Yarn
//
//  Created by Mark Jundo Documento on 9/4/15.
//  Code taken from http://stackoverflow.com/questions/3707427/how-to-read-data-from-nsfilehandle-line-by-line/3910036#3910036
//

#import <Foundation/Foundation.h>

@interface TextLineReader : NSObject

@property (nonatomic, readonly) NSString * filePath;

- (instancetype) initWithFilePath:(NSString *)path;
+ (instancetype) readerWithFilePath:(NSString *)path;

- (NSString *) readLine;
- (NSString *) readTrimmedLine;
- (void) enumerateLinesUsingBlock:(void(^)(NSString *line, BOOL *stop))block;
- (void) enumerateTrimmedLinesUsingBlock:(void(^)(NSString *line, BOOL *stop))block;

@end
