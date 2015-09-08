//
//  TextLineReader.m
//  Yarn
//
//  Created by Mark Jundo Documento on 9/4/15.
//  Code taken from http://stackoverflow.com/questions/3707427/how-to-read-data-from-nsfilehandle-line-by-line/3910036#3910036
//

#import "NSData+Range.h"
#import "TextLineReader.h"

@interface TextLineReader() {
    NSFileHandle *_fileHandle;
    unsigned long long _currentOffset;
    unsigned long long _totalFileLength;
    
    NSString *_lineDelimiter;
    NSUInteger _chunkSize;
}

@end

@implementation TextLineReader

- (instancetype) initWithFilePath:(NSString *)path {
    if (self = [super init]) {
        _fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
        if (_fileHandle == nil) {
            return nil;
        }
        
        _lineDelimiter = @"\n";
        _filePath = path;
        _currentOffset = 0ULL;
        _chunkSize = 10;
        [_fileHandle seekToEndOfFile];
        _totalFileLength = [_fileHandle offsetInFile];
        //we don't need to seek back, since readLine will do that.
    }
    
    return self;
}

+ (instancetype) readerWithFilePath:(NSString *)path {
    return [[TextLineReader alloc] initWithFilePath:path];
}

- (NSString *) readLine {
    if (_currentOffset >= _totalFileLength) {
        return nil;
    }
    
    NSData * newLineData = [_lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
    [_fileHandle seekToFileOffset:_currentOffset];
    NSMutableData * currentData = [[NSMutableData alloc] init];
    BOOL shouldReadMore = YES;
    
    while (shouldReadMore) {
        if (_currentOffset >= _totalFileLength) {
            break;
        }
        NSData * chunk = [_fileHandle readDataOfLength:_chunkSize];
        NSRange newLineRange = [chunk rangeOfData:newLineData];
        if (newLineRange.location != NSNotFound) {
            //include the length so we can include the delimiter in the string
            chunk = [chunk subdataWithRange:NSMakeRange(0, newLineRange.location + [newLineData length])];
            shouldReadMore = NO;
        }
        [currentData appendData:chunk];
        _currentOffset += [chunk length];
    }
    
    NSString *line = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
    return line;
}

- (NSString *) readTrimmedLine {
    return [[self readLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void) enumerateLinesUsingBlock:(void(^)(NSString *line, BOOL *stop))block {
    NSString * line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readLine])) {
        block(line, &stop);
    }
}

- (void)enumerateTrimmedLinesUsingBlock:(void (^)(NSString *line, BOOL *stop))block {
    [self enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        block([line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
               stop);
    }];
}

@end
