//
//  StorySettingsPageViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/24/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "Regex.h"
#import "StorySettingsPageViewController.h"
#import "ViewUtils.h"

@interface StorySettingsPageViewController ()

@property (nonatomic, strong) NSArray *views;

@end

@implementation StorySettingsPageViewController

- (instancetype)initWithStoryViewController:(StoryViewController *)storyViewController {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _storyViewController = storyViewController;
        [self createViews];
        [self setTitle:_LS(@"Story")];
    }
    
    return self;
}

- (void)createViews {
    _titleTexField = [UITextField new];
    [_titleTexField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [_titleTexField setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.1]];
    [_titleTexField setDelegate:self];
    [_titleTexField setPlaceholder:_LS(@"Untitled Story")];
    [_titleTexField setText:[[_storyViewController story] name]];
    
    _formatPickerView = [UIPickerView new];
    [_formatPickerView setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.1]];
    [_formatPickerView setDataSource:self];
    [_formatPickerView setDelegate:self];
    [_formatPickerView sizeToFit];
    for (StoryFormat *format in [_storyViewController formats]) {
        if ([[format name] isEqualToString:[[_storyViewController story] storyFormat]]) {
            NSInteger index = [[_storyViewController formats] indexOfObject:format];
            [_formatPickerView selectRow:index
                             inComponent:0
                                animated:NO];
            break;
        }
    }
    
    _proofingFormatPickerView = [UIPickerView new];
    [_proofingFormatPickerView setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.1]];
    [_proofingFormatPickerView setDataSource:self];
    [_proofingFormatPickerView setDelegate:self];
    [_proofingFormatPickerView sizeToFit];
    for (StoryFormat *format in [_storyViewController proofingFormats]) {
        if ([[format name] isEqualToString:[[_storyViewController proofingFormat] name]]) {
            NSInteger index = [[_storyViewController proofingFormats] indexOfObject:format];
            [_proofingFormatPickerView selectRow:index
                                     inComponent:0
                                        animated:NO];
            break;
        }
    }
    
    _views = @[@[@"Name",
                 _titleTexField,
                 [NSNumber numberWithDouble:30.0]],
               @[@"Story Format",
                 _formatPickerView,
                 [NSNumber numberWithDouble:CGRectGetHeight([_formatPickerView frame])]],
               @[@"Proofing Format",
                 _proofingFormatPickerView,
                 [NSNumber numberWithDouble:CGRectGetHeight([_proofingFormatPickerView frame])]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSArray *formats = (pickerView == _formatPickerView ?
                        [_storyViewController formats]:
                        [_storyViewController proofingFormats]);
    return [formats count];
}

- (NSString *)pickerView:(nonnull UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray *formats = (pickerView == _formatPickerView ?
                        [_storyViewController formats]:
                        [_storyViewController proofingFormats]);
    return [(StoryFormat *)[formats objectAtIndex:row] name];
}

#pragma mark UIPickerViewDelegate
- (void)pickerView:(nonnull UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == _formatPickerView) {
        [[_storyViewController story] setStoryFormat:
         [(StoryFormat *)[[_storyViewController formats] objectAtIndex:row] name]];
    }
    else {
        [_storyViewController setProofingFormat:
         [[_storyViewController formats] objectAtIndex:row]];
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(nonnull UITableView *)tableView {
    return [_views count];
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *name = [[_views objectAtIndex:[indexPath section]] objectAtIndex:0];
    UIView *view = [[_views objectAtIndex:[indexPath section]] objectAtIndex:1];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:name];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:name];
        ADD_SUBVIEW_FILL(cell.contentView, view);
        [cell prepareForReuse];
    }
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(nonnull UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _LS([[_views objectAtIndex:section] objectAtIndex:0]);
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [[[_views objectAtIndex:[indexPath section]] objectAtIndex:2] doubleValue];
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidEndEditing:(nonnull UITextField *)textField {
    NSString *name = TRIM([textField text]);
    if ([name notEmpty]) {
        [textField setText:name];
        [[_storyViewController story] setName:name];
    }
    else {
        [textField setText:[[_storyViewController story] name]];
    }
}

- (BOOL)textFieldShouldReturn:(nonnull UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
