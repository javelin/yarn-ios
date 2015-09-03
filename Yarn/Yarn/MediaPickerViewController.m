//
//  MediaPickerViewController.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/27/15.
//  Copyright © 2015 Mark Jundo Documento. All rights reserved.
//

#import "MediaPickerViewController.h"

@interface MediaPickerViewController ()

@end

@implementation MediaPickerViewController

@synthesize delegate = _delegate;

- (id)initWithIFId:(NSString *)ifId {
    self = [super initWithIFId:ifId];
    if (self) {
        self.collectionView.allowsMultipleSelection = NO;
        
        UIBarButtonItem *leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(handleCancelPick)];
        [[self navigationItem] setLeftBarButtonItem:leftBarButtonItem];
        
        NSMutableArray *array = [NSMutableArray array];
        if ([self albumsBarButtonItem]) {
            [array addObject:[self albumsBarButtonItem]];
        }
        if ([self cameraBarButtonItem]) {
            [array addObject:[self cameraBarButtonItem]];
        }
        [[self navigationItem] setRightBarButtonItems:array];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleCancelPick {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationController popViewControllerAnimated:YES];
    _selectedMediaPath = [self.imagesPath stringByAppendingPathComponent:
                          [[self sortedImageNames] objectAtIndex:[indexPath row]]];
    [_delegate performSelector:@selector(mediaPickerViewController:didPickImageAt:)
                    withObject:self
                    withObject:_selectedMediaPath];
}

@end
