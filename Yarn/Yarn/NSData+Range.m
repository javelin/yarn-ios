//
//  NSData+Range.m
//  Yarn
//
//  Created by Mark Jundo Documento on 9/4/15.
//  Code taken from http://stackoverflow.com/questions/3707427/how-to-read-data-from-nsfilehandle-line-by-line/3910036#3910036
//

#import "NSData+Range.h"

@implementation NSData (DDAdditions)

- (NSRange) rangeOfData:(NSData *)dataToFind {
    const void * bytes = [self bytes];
    NSUInteger length = [self length];
    
    const void * searchBytes = [dataToFind bytes];
    NSUInteger searchLength = [dataToFind length];
    NSUInteger searchIndex = 0;
    
    NSRange foundRange = {NSNotFound, searchLength};
    for (NSUInteger index = 0; index < length; index++) {
        if (((char *)bytes)[index] == ((char *)searchBytes)[searchIndex]) {
            //the current character matches
            if (foundRange.location == NSNotFound) {
                foundRange.location = index;
            }
            searchIndex++;
            if (searchIndex >= searchLength) { return foundRange; }
        } else {
            searchIndex = 0;
            foundRange.location = NSNotFound;
        }
    }
    return foundRange;
}

@end
