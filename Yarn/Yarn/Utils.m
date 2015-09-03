//
//  Utils.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "Constants.h"
#import "Regex.h"
#import "Utils.h"

NSString *AppDirectory() {
    static NSString *appDirectory;
    if (!appDirectory) {
        appDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    }
    return appDirectory;
}

NSString *AppName() {
    static NSString *appName;
    if (!appName) {
        appName = BUNDLE_VALUE((NSString *)kCFBundleNameKey);
    }
    return appName;
}

NSString *AppVersion() {
    static NSString *appVersion;
    if (!appVersion) {
        appVersion = BUNDLE_VALUE((NSString *)kCFBundleVersionKey);
    }
    return appVersion;
}

BOOL CreateDir(NSString *path, BOOL overwrite, NSError **error) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists, isDir;
    exists = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    NSError *error_ = nil;
    if (exists) {
        if (overwrite || !isDir) {
            [fileManager removeItemAtPath:path error:&error_];
            if (error_) {
                if (error) {
                    *error = error_;
                }
                return NO;
            }
        }
        else {
            return NO;
        }
    }
    [fileManager createDirectoryAtPath:path
           withIntermediateDirectories:NO
                            attributes:nil
                                 error:&error_];
    if (error) {
        *error = error_;
    }
    
    return error_ == nil;
}

void DispatchAsync(dispatch_block_t block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

void DispatchAsyncMain(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

void DispatchMainAfter(NSTimeInterval interval, dispatch_block_t block) {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW,
                                          (dispatch_time_t)round(interval * (NSTimeInterval)NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), block);
}

NSString *SanitizeString(NSString *s, BOOL showLinks) {
    static Regex *regex1 = nil, *regex2 = nil;
    if (!regex1) {
        regex1 = [Regex regex:@"<a.*?href=\"(.*?)\".*?>(.*?)</a>"];
        regex2 = [Regex regex:@"<.*?>"];
    }
    
    NSString *string = s;
    if (showLinks) {
        string = [regex1 replace:string template:@"$2 [$1]"];
    }
    string = [regex2 replace:string template:@""];
    return string;
}

NSString *TwineVersion() {
    static NSString *twineVersion;
    if (!twineVersion) {
        twineVersion = BUNDLE_VALUE((NSString *)kBundleTwineVersionKey);
    }
    return twineVersion;
}

NSString *XMLEscape(NSString *string) {
    return [[[[[string stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"]
               stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"]
              stringByReplacingOccurrencesOfString: @"'" withString: @"&apos;"]
             stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]
            stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];
}
