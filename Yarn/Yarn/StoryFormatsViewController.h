//
//  StoryFormatsViewController.h
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "HomeViewController.h"

@interface StoryFormatsViewController : UITableViewController <EntityList>

@property (nonatomic, readonly) NSArray *builtInFormatNames;
@property (nonatomic, readonly) NSArray *storyFormats;

- (instancetype)initWithBuiltInFormats:(NSArray *)formats proofing:(BOOL)proofing;

@end
