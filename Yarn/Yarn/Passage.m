//
//  Passage.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/13/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "Passage.h"
#import "Regex.h"
#import "Story.h"
#import "Utils.h"

@interface Passage() {
    NSMutableArray *_tags;
}
@end

@implementation Passage

@synthesize tags = _tags;

static NSString *_template = @"<tw-passagedata pid=\"%@\" name=\"%@\" tags=\"%@\" position=\"%0.f,%0.f\">%@</tw-passagedata>";
static NSString *_noNameError = @"You must give this passage a name.";
static NSString *_duplicateNameError = @"There is already a passage named \"%@.\" Please give this one a unique name.";

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _initWithStory:nil Id:-1];
    }
    
    return self;
}

- (instancetype)initWithStory:(Story *)story {
    self = [super init];
    if (self) {
        [self _initWithStory:story Id:-1];
    }
    
    return self;
}

- (instancetype)initWithStory:(Story *)story Id:(NSInteger)Id {
    self = [super init];
    if (self) {
        [self _initWithStory:story Id:Id];
    }
    
    return self;
}

- (void)_initWithStory:(Story *)story Id:(NSInteger)Id {
    _Id = Id > 0 ? Id:(story ? [story nextId]:-1);
    _story = story;
    _name = @"Untitled Passage";
    _text = @"";
    _top = 0.0;
    _left = 0.0;
    _tags = [NSMutableArray array];
}

+ (instancetype)passageInStory:(Story *)story {
    return [[Passage alloc] initWithStory:story];
}

+ (instancetype)passageInStory:(Story *)story named:(NSString *)name {
    Passage *passage = [Passage passageInStory:(Story *)story];
    [passage setName:name];
    return passage;
}

+ (instancetype)passageInStory:(Story *)story Id:(NSInteger)Id named:(NSString *)name text:(NSString *)text tags:(NSArray *)tags {
    Passage *passage = [[Passage alloc] initWithStory:story Id:Id];
    [passage setName:name];
    [passage setText:text];
    [passage setTags:tags];
    return passage;
}

- (NSString *)excerpt {
    return self.text.length >= 100 ? [[self.text substringToIndex:99] stringByAppendingString:@"..."]:self.text;
}

- (NSArray *)links:(BOOL)internalOnly {
    Regex *regex = [Regex regex:@"\\[\\[.*?\\]\\]"];
    
    Regex *type1a = [Regex regex:@"\\[\\[([^\\|\\]]*?)\\->([^\\|\\]]*)?\\]\\]"]; // [[display text->link]] format
    Regex *type1b = [Regex regex:@"\\[\\[([^\\|\\]]*?)<\\-([^\\|\\]]*)?\\]\\]"]; // [[link<-display text]] format
    Regex *type2 = [Regex regex:@"\\[\\[([^\\|\\]]*?)\\|([^\\|\\]]*)?\\]\\]"]; // [[display text|link]] format
    Regex *type3 = [Regex regex:@"\\[\\[|\\]\\]"]; // [[link]] format
    Regex *oldTypeSetters = [Regex regex:@"\\[(\\[.*?\\])(\\[.*?\\])\\]"]; // [[link][variable setter]] or [[display text|link][variable setter]]
    
    Regex *externalLink = [Regex regex:@"^\\w+:\\/\\/\\/?\\w"];
    
    NSArray *matches = [regex matchAll:_text];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:matches.count];
    for (RegexMatch *match in matches) {
        NSString *link = [match group:0];
        if ([link notEmpty]) {
            link = [type1a replace:link template:@"$2"];
            link = [type1b replace:link template:@"$1"];
            link = [oldTypeSetters replace:link template:@"[$1]"];
            link = [type2 replace:link template:@"$2"];
            link = [type3 replace:link template:@""];
            
            if ([link notEmpty]) {
                if (internalOnly) {
                    if ([externalLink matchOne:link]) {
                        continue;
                    }
                }
                [array addObject:[link stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }
        }
    }
    
    return [[NSSet setWithArray:array] allObjects];
}

- (NSString *)publish:(NSInteger)Id {
    NSString *tags = [_tags count] ? [_tags componentsJoinedByString:@" "]:@"";
    return [NSString stringWithFormat:_template, [@(Id) stringValue],
            _name, XMLEscape(tags), _left, _top, XMLEscape(_text)];
}

- (void)setTags:(NSArray *)tags {
    _tags = tags ? [NSMutableArray arrayWithArray:[[NSSet setWithArray:tags] allObjects]]:nil;
}

- (NSString *)validate {
    if (![self.name notEmpty]) {
        return _LS(_noNameError);
    }
    else {
        Passage *p = [_story getPassageWithName:_name];
        if (p && [p Id] != _Id) {
            return [NSString stringWithFormat:_LS(_duplicateNameError), _name];
        }
    }
    return @"";
}

@end
