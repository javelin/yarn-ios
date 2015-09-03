//
//  Constants.m
//  Yarn
//
//  Created by Mark Jundo Documento on 6/1/15.
//  Copyright (c) 2015 Mark Documento. All rights reserved.
//

#import "Constants.h"

const NSString *kBundleTwineVersionKey = @"com.mjdocumento.twine.version";
const NSString *kBundleYarnSourceURL = @"com.mjdocumento.yarn.source.url";
const NSString *kBundleMyEmail = @"com.mjdocumento.my.email";
const NSTimeInterval kYarnDefaultAutosaveInterval = 300.0; // five minutes
const NSString *kYarnDefaultProofingFormat = @"Harlowe";
const NSString *kYarnDefaultStoryFormat = @"Paperthin";

const CGFloat kYarnFontSizeAutosave = 10.0;
const CGFloat kYarnFontSizeAutosaveIpad = 12.0;
const CGFloat kYarnFontSizeSnapToGrid = 10.0;
const CGFloat kYarnFontSizeSnapToGridIpad = 12.0;

const NSString *kYarnKeyDefaultStoryFormat = @"com.mjdocumento.default.story.format";
const NSString *kYarnKeyProofingFormat = @"com.mjdocumento.proofing.format";
const NSString *kYarnKeySnapToGrid = @"com.mjdocumento.snap.to.grid";

const NSString *kYarnStoryImportDir = @"import";
const NSString *kYarnStoryFormatSaveDir = @"formats";
const NSString *kYarnStoryProofingFormatSaveDir = @"proofing-formats";
const NSString *kYarnStorySaveDir = @"stories";

const NSInteger kDuplicatePassageName = -1;
const NSInteger kNoPath = -2;
const NSInteger kNoStartingPoint = -3;
const NSInteger kStartingPointNonExistent = -4;
const NSInteger kInvalidPath = -5;
const NSInteger kCantOpenArchive = -6;
const NSInteger kCantWriteToArchive = -7;
const NSInteger kCantCloseArchive = -8;
const NSInteger kInvalidTwine2File = -9;
