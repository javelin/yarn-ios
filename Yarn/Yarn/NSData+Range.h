//
//  NSData+Range.h
//  Yarn
//
//  Created by Mark Jundo Documento on 9/4/15.
//  Code taken from http://stackoverflow.com/questions/3707427/how-to-read-data-from-nsfilehandle-line-by-line/3910036#3910036
//

#import <Foundation/Foundation.h>

@interface NSData (Range)

- (NSRange)rangeOfData:(NSData *)dataToFind;

@end
