//
//  AlbumPickerController.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>
#import "ELCConstants.h"


@interface ELCAlbumPickerController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) ALAssetsLibrary *library;
@property (strong) PHCachingImageManager *imageManager;

@end

static CGSize const kAlbumThumbnailSize1 = {70.0f , 70.0f};

@implementation ELCAlbumPickerController

//Using auto synthesizers

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	
	[self.navigationItem setTitle:NSLocalizedString(@"Loading...", nil)];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelImagePicker)];
	[self.navigationItem setRightBarButtonItem:cancelButton];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetLibrary;
    
    self.imageManager = [[PHCachingImageManager alloc] init];

//        //if ios 8 and above
        NSLog(@"authorization status %li", (long)[PHPhotoLibrary authorizationStatus]);
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
//        [self updateFetchResults];
}

-(void)updateFetchResults
{
    //What I do here is fetch both the albums list and the assets of each album.
    //This way I have acces to the number of items in each album, I can load the 3
    //thumbnails directly and I can pass the fetched result to the gridViewController.
    
    [self.assetGroups removeAllObjects];

    //Fetch PHAssetCollections:
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    //options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", @[@(PHAssetMediaTypeImage)]];
    //options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
    
    if (assetsFetchResult != nil)
        [self.assetGroups addObject:@{@"All Photos":assetsFetchResult}];

    //Smart Albums
    PHFetchResult *smartCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [self addPHCollectionListToTheAssetGroups:smartCollections];
    
    //Created by the user
    PHFetchResult *userCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    [self addPHCollectionListToTheAssetGroups:userCollections];
    
    [self reloadTableView];
}

- (void) addPHCollectionListToTheAssetGroups:(PHFetchResult *) collectionsResult {
    
    for(PHCollection *collection in collectionsResult)
    {
        NSLog(@"album title %@", collection.localizedTitle);
        
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            //Albums collections are allways PHAssetCollectionType=1 & PHAssetCollectionSubtype=2
            
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
            if (assetsFetchResult.count > 0) {
                [self.assetGroups addObject:@{collection.localizedTitle : assetsFetchResult}];
            }
        }
    }
    
}


- (void)viewWillAppear:(BOOL)animated {
    
    [self updateFetchResults];
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)reloadTableView
{
	[self.tableView reloadData];
	[self.navigationItem setTitle:NSLocalizedString(@"Select an Album", nil)];
}

- (BOOL)shouldSelectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount
{
    return [self.parent shouldSelectAsset:asset previousCount:previousCount];
}

- (BOOL)shouldDeselectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount
{
    return [self.parent shouldDeselectAsset:asset previousCount:previousCount];
}

- (void)selectedAssets:(NSArray*)assets
{
	[_parent selectedAssets:assets];
}

- (ALAssetsFilter *)assetFilter
{
    if([self.mediaTypes containsObject:(NSString *)kUTTypeImage] && [self.mediaTypes containsObject:(NSString *)kUTTypeMovie])
    {
        return [ALAssetsFilter allAssets];
    }
    else if([self.mediaTypes containsObject:(NSString *)kUTTypeMovie])
    {
        return [ALAssetsFilter allVideos];
    }
    else
    {
        return [ALAssetsFilter allPhotos];
    }
}

/*
 * The user tap the cancel button
 */
- (void)cancelImagePicker {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (IS_IPHONE){
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [app.detailViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    app.isUploadViewVisible = NO;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
//    if(indexPath.row == 0) {
    
//        ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row-1];
//        [g setAssetsFilter:[self assetFilter]];
//        NSInteger gCount = [g numberOfAssets];
//        
//        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)",[g valueForProperty:ALAssetsGroupPropertyName], (long)gCount];
//        UIImage* image = [UIImage imageWithCGImage:[g posterImage]];
//        image = [self resize:image to:CGSizeMake(78, 78)];
//        [cell.imageView setImage:image];
//        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        
        // } else {         if ios 8 and above
        NSDictionary *currentFetchResultRecord = [self.assetGroups objectAtIndex:indexPath.row];
        PHFetchResult *assetsFetchResult = [currentFetchResultRecord allValues][0];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %lu", [currentFetchResultRecord allKeys][0],(unsigned long)assetsFetchResult.count];
        if([assetsFetchResult count]>0)
        {
            CGFloat scale = [UIScreen mainScreen].scale;
            
            //Compute the thumbnail pixel size:
            CGSize tableCellThumbnailSize1 = CGSizeMake(kAlbumThumbnailSize1.width*scale, kAlbumThumbnailSize1.height*scale);
            PHAsset *asset = assetsFetchResult[0];
            
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            
            // Download from cloud if necessary
            options.networkAccessAllowed = YES;
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                
            };
            
            [self.imageManager requestImageForAsset:asset
                                         targetSize:tableCellThumbnailSize1
                                        contentMode:PHImageContentModeAspectFill
                                            options:options
                                      resultHandler:^(UIImage *result, NSDictionary *info)
             {
                 if(cell.tag == currentTag) {
                     cell.imageView.image = [self resize:result to:CGSizeMake(78, 78)];
                 }
             }];
        }else {
            cell.imageView.image = nil;
        }
        

    return cell;
}

// Resize a UIImage. From http://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
- (UIImage *)resize:(UIImage *)image to:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName: nil bundle: nil];
	picker.parent = self;

    picker.assetGroup = [[self.assetGroups objectAtIndex:indexPath.row] allValues][0];
    picker.assetPickerFilterDelegate = self.assetPickerFilterDelegate;
	
	[self.navigationController pushViewController:picker animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 95;
}


#pragma mark - Photos Observer

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *updatedCollectionsFetchResults = nil;
        
        for (NSDictionary *fetchResultDictionary in self.assetGroups) {
            PHFetchResult *collectionsFetchResult = [fetchResultDictionary allValues][0];
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            if (changeDetails) {
                
                if (!updatedCollectionsFetchResults) {
                    updatedCollectionsFetchResults = [self.assetGroups mutableCopy];
                }
                
                [updatedCollectionsFetchResults replaceObjectAtIndex:[self.assetGroups indexOfObject:fetchResultDictionary] withObject:@{[fetchResultDictionary allKeys][0] :[changeDetails fetchResultAfterChanges]}];
            }
        }
        
        if (updatedCollectionsFetchResults) {
            self.assetGroups = updatedCollectionsFetchResults;
            [self.tableView reloadData];
        }
        
    });
}
@end

