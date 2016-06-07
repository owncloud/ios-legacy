//
//  ELCAssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "ELCConsole.h"
#import "ELCConstants.h"
#import <Photos/Photos.h>


@interface ELCAssetTablePicker () <PHPhotoLibraryChangeObserver>

@property (nonatomic, assign) int columns;

@end

@implementation ELCAssetTablePicker

//Using auto synthesizers

- (id)init
{
    self = [super init];
    if (self) {
        //Sets a reasonable default bigger then 0 for columns
        //So that we don't have a divide by 0 scenario
        self.columns = 4;
    }
    return self;
}

- (void)viewDidLoad
{
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
	
    if (self.immediateReturn) {
        
    } else {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
        [self.navigationItem setTitle:NSLocalizedString(@"Loading...", nil)];
    }

	
    
    // Register for notifications when the photo library has changed
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.columns = self.view.bounds.size.width / 80;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ELCConsole mainConsole] removeAllIndex];
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    ELCAssetCell *topCellVisible = [[[self tableView] visibleCells] objectAtIndex: 0];
    
    NSIndexPath* pathOfTheCell = [self.tableView indexPathForCell:topCellVisible];
    long currentRow = [pathOfTheCell row];
    DLog(@"Number: %ld", currentRow);
    
    NSInteger numberOfRowInView = [[[self tableView] visibleCells] count];
    NSInteger currentImagesAtEachRow = 0;
    NSInteger futureImagesAtEachRow = 0;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        currentImagesAtEachRow = (NSInteger)(self.view.frame.size.width/78);
        futureImagesAtEachRow = (NSInteger)((self.view.frame.size.height + self.navigationController.navigationBar.frame.size.height+20)/78);
    } else {
        currentImagesAtEachRow = 6;
        futureImagesAtEachRow = 6;
    }
    
    DLog(@"numberOfRowInView: %ld", (long)numberOfRowInView);
    DLog(@"currentImagesAtEachRow: %ld", (long)currentImagesAtEachRow);
    DLog(@"futureImagesAtEachRow: %ld", (long)futureImagesAtEachRow);
    
    _rowToScrollAfterRotation = ((currentRow*currentImagesAtEachRow)/futureImagesAtEachRow);
    if (_rowToScrollAfterRotation != 0) {
        _rowToScrollAfterRotation = _rowToScrollAfterRotation  + numberOfRowInView-1;
    }
    
    DLog(@"A: %ld", (long)[self.tableView numberOfRowsInSection:0]);
    DLog(@"B: %ld", currentRow);
    
    
    //Check if is near to bottom
    if (([self.tableView numberOfRowsInSection:0] - (currentRow+1)) <= numberOfRowInView) {
        _isNearToBottom = YES;
    } else {
        _isNearToBottom = NO;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.tableView reloadData];
    
    // scroll to _rowToScrollAfterRotation
    long section = [self numberOfSectionsInTableView:self.tableView] - 1;
    long row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
    if (section >= 0 && row >= 0) {
        
        DLog(@"self.tableView numberOfRowsInSection:0]: %ld", (long)[self.tableView numberOfRowsInSection:0]);
        DLog(@"_rowToScrollAfterRotation: %ld", _rowToScrollAfterRotation);
        DLog(@"([self.tableView numberOfRowsInSection:0] - _rowToScrollAfterRotation): %ld", ([self.tableView numberOfRowsInSection:0] - _rowToScrollAfterRotation));
        
        //In case we are more under the bottom (out of array) or we are really near to the bottom then we go to the bottom
        if ([self.tableView numberOfRowsInSection:0] <= _rowToScrollAfterRotation || (_isNearToBottom && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)                               )) {
            _rowToScrollAfterRotation = [self.tableView numberOfRowsInSection:0]-1;
        }
        
        
        NSIndexPath *ip = [NSIndexPath indexPathForRow:_rowToScrollAfterRotation
                                             inSection:section];
        [self.tableView scrollToRowAtIndexPath:ip
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:NO];
    }
        
}

- (void)preparePhotos
{
    @autoreleasepool {
        
        [self.elcAssets removeAllObjects];
        
        PHFetchResult *tempFetchResult = (PHFetchResult *)self.assetGroup;
        for (int k =0; k < tempFetchResult.count; k++) {
            PHAsset *asset = tempFetchResult[k];
            ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:asset];
            [elcAsset setParent:self];
            
            BOOL isAssetFiltered = NO;
            if (self.assetPickerFilterDelegate &&
                [self.assetPickerFilterDelegate respondsToSelector:@selector(assetTablePicker:isAssetFilteredOut:)])
            {
                isAssetFiltered = [self.assetPickerFilterDelegate assetTablePicker:self isAssetFilteredOut:(ELCAsset*)elcAsset];
            }
            
            if (!isAssetFiltered) {
                [self.elcAssets addObject:elcAsset];
            }
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            // scroll to bottom
            long section = [self numberOfSectionsInTableView:self.tableView] - 1;
            long row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
            if (section >= 0 && row >= 0) {
                NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                     inSection:section];
                [self.tableView scrollToRowAtIndexPath:ip
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
            }
            
            [self.navigationItem setTitle:self.assetGroupName];
        });
    }
}


- (void)doneAction:(id)sender
{
	NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
    
	for (ELCAsset *elcAsset in self.elcAssets) {
		if ([elcAsset selected]) {
			[selectedAssetsImages addObject:elcAsset];
		}
	}
    if ([[ELCConsole mainConsole] onOrder]) {
        [selectedAssetsImages sortUsingSelector:@selector(compareWithIndex:)];
    }
    [self.parent selectedAssets:selectedAssetsImages andURL:self.currentRemoteFolder];
}


- (BOOL)shouldSelectAsset:(ELCAsset *)asset
{
    NSUInteger selectionCount = 0;
    for (ELCAsset *elcAsset in self.elcAssets) {
        if (elcAsset.selected) selectionCount++;
    }
    BOOL shouldSelect = YES;
    if ([self.parent respondsToSelector:@selector(shouldSelectAsset:previousCount:)]) {
        shouldSelect = [self.parent shouldSelectAsset:asset previousCount:selectionCount];
    }
    return shouldSelect;
}

- (void)assetSelected:(ELCAsset *)asset
{
    if (self.singleSelection) {

        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
}

- (BOOL)shouldDeselectAsset:(ELCAsset *)asset
{
    if (self.immediateReturn){
        return NO;
    }
    return YES;
}

- (void)assetDeselected:(ELCAsset *)asset
{
    if (self.singleSelection) {
        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }

    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset.asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
    
    int numOfSelectedElements = [[ELCConsole mainConsole] numOfSelectedElements];
    if (asset.index < numOfSelectedElements - 1) {
        NSMutableArray *arrayOfCellsToReload = [[NSMutableArray alloc] initWithCapacity:1];
        
        for (int i = 0; i < [self.elcAssets count]; i++) {
            ELCAsset *assetInArray = [self.elcAssets objectAtIndex:i];
            if (assetInArray.selected && (assetInArray.index > asset.index)) {
                assetInArray.index -= 1;
                
                int row = i / self.columns;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                BOOL indexExistsInArray = NO;
                for (NSIndexPath *indexInArray in arrayOfCellsToReload) {
                    if (indexInArray.row == indexPath.row) {
                        indexExistsInArray = YES;
                        break;
                    }
                }
                if (!indexExistsInArray) {
                    [arrayOfCellsToReload addObject:indexPath];
                }
            }
        }
        [self.tableView reloadRowsAtIndexPaths:arrayOfCellsToReload withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.columns <= 0) { //Sometimes called before we know how many columns we have
        self.columns = 4;
    }
    NSInteger numRows = ceil([self.elcAssets count] / (float)self.columns);
    return numRows;
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    long index = path.row * self.columns;
    long length = MIN(self.columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {		        
        cell = [[ELCAssetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setAssets:[self assetsForIndexPath:indexPath]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 79;
}

- (int)totalSelectedAssets
{
    int count = 0;
    
    for (ELCAsset *asset in self.elcAssets) {
		if (asset.selected) {
            count++;	
		}
	}
    
    return count;
}

#pragma mark - Photo Library Observer 

-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:(PHFetchResult*)self.assetGroup];
    
    if(changeDetails) {
        self.assetGroup = [changeDetails fetchResultAfterChanges];
        [self preparePhotos];
    }
}


@end
