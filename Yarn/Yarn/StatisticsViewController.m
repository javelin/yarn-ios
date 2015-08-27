//
//  StatisticsViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/26/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "Passage.h"
#import "Regex.h"
#import "StatisticsViewController.h"
#import "Story.h"
#import "ViewUtils.h"

@interface StatisticsViewController ()

@end

@implementation StatisticsViewController

static NSString *template = @"<html><head><style>body, p, td {font-family: helvetica,arial,sans-serif; font-size:16px;}</style></head><html><body>%@<p>&nbsp;</p><p>%@ %@.</p><p>%@ %@. (<a href=\"http://ifdb.tads.org/help-ifid\">%@</a>)</p></body></html>";

- (instancetype)initWithStory:(Story *)story {
    self = [super init];
    if (self) {
        _story = story;
        _textView = [UITextView new];
        [_textView setBackgroundColor:[[UIColor lightGrayColor]
                                       colorWithAlphaComponent:0.1]];
        [_textView setEditable:NO];
        [self setView:_textView];
        [self setTitle:_LS(@"Statistics")];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_story) {
        return;
    }
    SHOW_WAIT();
    DISPATCH_ASYNC(^{
        NSInteger chars = 0, words = 0, links = 0, brokenLinks = 0;
        Regex *regex = [Regex regex:@"\\b\\W+\\b"];
        for (Passage *passage in [[_story passages] allValues]) {
            chars += [[passage text] length];
            words += [[regex matchAll:[passage text]] count];
            for (NSString *link in [passage links:YES]) {
                if (![_story getPassageWithName:link]) {
                    ++brokenLinks;
                }
            }
            links += [[passage links:NO] count];
            
        }
        
        NSDictionary *dict = @{ _LS(@"Characters"):[NSNumber numberWithInteger:chars],
                                _LS(@"Words"):[NSNumber numberWithInteger:words],
                                _LS(@"Passages"):[NSNumber numberWithInteger:[[_story passages] count]],
                                _LS(@"Links"):[NSNumber numberWithInteger:links],
                                _LS(@"Broken Links"):[NSNumber numberWithInteger:brokenLinks]};
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:@"<table style=\"margin:0 auto; width:100%;\">"];
        for (NSString *key in dict.allKeys) {
            NSNumber *value = [dict objectForKey:key];
            [array addObject:@"<tr>"];
            [array addObject:[NSString stringWithFormat:@"<td style=\"text-align:right; font-weight:bold; font-size:16px; width:50%%;\">%d&nbsp;</td><td>&nbsp;%@</td>", [value intValue], key]];
            [array addObject:@"</tr>"];
        }
        [array addObject:@"</table>"];
        
        NSString *html = [NSString stringWithFormat:template,
                          [array componentsJoinedByString:@"\n"],
                          _LS(@"This story was last changed at"),
                          [NSDateFormatter localizedStringFromDate:[_story lastUpdate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle],
                          _LS(@"The IFID for this story is"),
                          [_story ifId],
                          _LS(@"What is an IFID?")
                          ];
        _story = nil;
        DISPATCH_ASYNC_MAIN(^{
            NSAttributedString *attribStr =
            [[NSAttributedString alloc] initWithData:[html
                                                      dataUsingEncoding:NSUTF8StringEncoding]
                                             options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                  documentAttributes:nil
                                               error:nil];
            [_textView setAttributedText:attribStr];
            HIDE_WAIT();
        });
    });
}

@end
