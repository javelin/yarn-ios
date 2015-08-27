//
//  StoryFormatViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/27/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "Constants.h"
#import "StoryFormatViewController.h"
#import "ViewUtils.h"

@interface StoryFormatViewController () {
    BOOL _proofing;
    BOOL _isDefault;
}

@end

@implementation StoryFormatViewController

static NSString *template = @"<html><head><style>body, p {font-family: helvetica,arial,sans-serif; font-size:16px;}</style></head><html><body><h3>%@ %@</h3><p>by: %@</p><p>%@</p><p><a href=\"%@\">%@</a></p></body></html>";

- (instancetype)initWithStoryFormat:(StoryFormat *)storyFormat {
    self = [super init];
    if (self) {
        _proofing = [storyFormat isProofing];
        _isDefault = [[self currentDefaultFormat] isEqualToString:[storyFormat name]];
        [self setTitle:[storyFormat name]];
        
        [self createViews];
        [self addConstraints];
        
        NSAttributedString *attribStr =
        [[NSAttributedString alloc] initWithData:[[NSString stringWithFormat:template,
                                                   [storyFormat name],
                                                   [[storyFormat properties] objectForKey:@"version"],
                                                   [[storyFormat properties] objectForKey:@"author"],
                                                   [[storyFormat properties] objectForKey:@"description"],
                                                   [[storyFormat properties] objectForKey:@"url"],
                                                   [[storyFormat properties] objectForKey:@"url"]]
                                                  dataUsingEncoding:NSUTF8StringEncoding]
                                         options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                              documentAttributes:nil
                                           error:nil];
        [_infoTextView setAttributedText:attribStr];
    }
    
    return self;
}

- (void)addConstraints {
    CONSTRAINT_EQ([self view], _infoTextView, Top, [self view], Top, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _infoTextView, Left, [self view], Left, 1.0, 10.0);
    CONSTRAINT_EQ([self view], _infoTextView, Right, [self view], Right, 1.0, -10.0);
    CONSTRAINT_EQ([self view], _infoTextView, Height, nil, Height, 1.0, 250.0);
    
    CONSTRAINT_EQ([self view], _defaultButton, Top, _infoTextView, Bottom, 1.0, 20.0);
    CONSTRAINT_EQ([self view], _defaultButton, CenterX, [self view], CenterX, 1.0, 0.0);
    CONSTRAINT_GEQ([self view], _defaultButton, Width, nil, Width, 1.0, 300.0);
}

- (void)createViews {
    [self setView:[UIView new]];
    [[self view] setBackgroundColor:[UIColor whiteColor]];
    
    INIT_VIEW(UITextView, _infoTextView, [self view]);
    [_infoTextView setBackgroundColor:[UIColor whiteColor]];
    [_infoTextView setEditable:NO];
    
    INIT_VIEW(UIButton, _defaultButton, [self view]);
    [_defaultButton setBackgroundColor:[UIColor darkGrayColor]];
    [_defaultButton setEnabled:!_isDefault];
    [_defaultButton setTitle:(_isDefault ? _LS(@"This is the default format."):
                              _LS(@"Make this the default format."))
                    forState:UIControlStateNormal];
    [_defaultButton setTitleColor:[UIColor whiteColor]
                    forState:UIControlStateNormal];
    [_defaultButton setTitleColor:[UIColor lightGrayColor]
                         forState:UIControlStateDisabled];
    [_defaultButton addTarget:self
                       action:@selector(handleTapDefaultFormat)
             forControlEvents:UIControlEventTouchUpInside];
}

- (NSString *)currentDefaultFormat {
    if (_proofing) {
        return [[NSUserDefaults standardUserDefaults]
                objectForKey:(NSString *)kYarnKeyProofingFormat];
    }
    return [[NSUserDefaults standardUserDefaults]
            objectForKey:(NSString *)kYarnKeyDefaultStoryFormat];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleTapDefaultFormat {
    if (_proofing) {
        [[NSUserDefaults standardUserDefaults] setObject:[self title]
                                                  forKey:(NSString *)kYarnKeyProofingFormat];
        AlertInfo(_LS(@"Default Proofing Format"),
                  _LS(@"This is now the default proofing format."),
                  _LS(@"Close"),
                  self);
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:[self title]
                                                  forKey:(NSString *)kYarnKeyDefaultStoryFormat];
        AlertInfo(_LS(@"Default Story Format"),
                  _LS(@"This is now the default story format."),
                  _LS(@"Close"),
                  self);
    }
    [_defaultButton setTitle:_LS(@"This is the default format.") forState:UIControlStateNormal];
    [_defaultButton setEnabled:NO];
}

@end
