//
//  AssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "OCELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "UIColor+Constants.h"

@interface OCELCAssetTablePicker ()

@property (nonatomic, assign) int columns;

@end

@implementation OCELCAssetTablePicker

@synthesize parent = _parent;;
@synthesize selectedAssetsLabel = _selectedAssetsLabel;
@synthesize assetGroup = _assetGroup;
@synthesize elcAssets = _elcAssets;
@synthesize singleSelection = _singleSelection;
@synthesize columns = _columns;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
    if (self.immediateReturn) {
        
    } else {
        UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"upload", nil) style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)] autorelease];
        
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
        [self.navigationItem setTitle:NSLocalizedString(@"loading", nil)];
        
    }

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

#pragma mark - Rotation Methods

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
    
    [self.navigationItem setTitle:[NSString stringWithFormat:@"%@",[_assetGroup valueForProperty:ALAssetsGroupPropertyName]]];
    
}

- (void)preparePhotos
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"enumerating photos");
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result == nil) {
            return;
        }

        ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
        [elcAsset setParent:self];
        [self.elcAssets addObject:elcAsset];
        [elcAsset release];
     }];
    NSLog(@"done enumerating photos");
    
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
        
        [self.navigationItem setTitle:[NSString stringWithFormat:@"%@",[_assetGroup valueForProperty:ALAssetsGroupPropertyName]]];
    });
    
    [pool release];

}

- (void)doneAction:(id)sender
{	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
	    
	for(ELCAsset *elcAsset in self.elcAssets) {

		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [self.parent selectedAssets:selectedAssetsImages andURL:_currentRemoteFolder];
}

- (void)assetSelected:(id)asset
{
    if (self.singleSelection) {

        for(ELCAsset *elcAsset in self.elcAssets) {
            if(asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = [NSArray arrayWithObject:[asset asset]];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
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
    self.columns = self.view.bounds.size.width / 80;
    
    return ceil([self.elcAssets count] / (float)self.columns);
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
        
    ELCAssetCell *cell = nil;

    //We force to reinitialice the Cell becouse on iPad at iOS7 not appear clear the last row
    //if (cell == nil) {
    cell = [[[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier] autorelease];

    //} else {
	//	[cell setAssets:[self assetsForIndexPath:indexPath]];
	//}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79;
}

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) {
		if([asset selected]) {   
            count++;	
		}
	}
    
    return count;
}

- (void)dealloc 
{
    [_assetGroup release];    
    [_elcAssets release];
    [_selectedAssetsLabel release];
    [super dealloc];    
}

@end
