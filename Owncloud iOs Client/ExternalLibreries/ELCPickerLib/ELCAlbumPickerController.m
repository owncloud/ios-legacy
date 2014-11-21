//
//  AlbumPickerController.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "AppDelegate.h"
#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "OCELCAssetTablePicker.h"
#import "Customization.h"
#import "AppDelegate.h"
#import "SelectFolderViewController.h"
#import "constants.h"
#import "UIColor+Constants.h"
#import "UtilsUrls.h"

@interface ELCAlbumPickerController ()

@property (nonatomic, retain) ALAssetsLibrary *library;

@end

@implementation ELCAlbumPickerController

@synthesize parent = _parent;
@synthesize assetGroups = _assetGroups;
@synthesize library = _library;

#pragma mark -
#pragma mark View lifecycle

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.currentViewVisible = self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self.navigationItem setTitle:NSLocalizedString(@"loading", nil)];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
	[self.navigationItem setRightBarButtonItem:cancelButton];
	[cancelButton release];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    [tempArray release];
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetLibrary;
    [assetLibrary release];

    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
        {
            if (group == nil) {
                return;
            }
            
            // added fix for camera albums order
            NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
            
            if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
                [self.assetGroups insertObject:group atIndex:0];
            }
            else {
                [self.assetGroups addObject:group];
            }

            // Reload albums
            [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:[NSLocalizedString(@"no_access_to_gallery", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            [alert release];
            
            NSLog(@"A problem occured %@", [error description]);	                                 
        };	
                
        // Enumerate Albums
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                               usingBlock:assetGroupEnumerator 
                             failureBlock:assetGroupEnumberatorFailure];
        
        [pool release];
        
        [self addToolBar];
    });    
}

- (void)reloadTableView
{
	[self.albumPickerTableView reloadData];
	[self.navigationItem setTitle:NSLocalizedString(@"photo_albums", nil)];
}
     
-(void)selectedAssets:(NSArray*)assets andURL:(NSString*)urlToUpload {
	[_parent selectedAssets:assets andURL:urlToUpload];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row];
    //[g setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSInteger gCount = [g numberOfAssets];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)",[g valueForProperty:ALAssetsGroupPropertyName], (long)gCount];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row] posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	OCELCAssetTablePicker *picker = [[OCELCAssetTablePicker alloc] initWithNibName: nil bundle: nil];
	picker.parent = self;
    picker.currentRemoteFolder = _currentRemoteFolder;

    picker.assetGroup = [self.assetGroups objectAtIndex:indexPath.row];
    //[picker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
	[self.navigationController pushViewController:picker animated:YES];
	[picker release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 57;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc 
{	
    [_assetGroups release];
    [_library release];
    [super dealloc];
}


///-----------------------------------
/// @name addToolBar
///-----------------------------------
     
/**
 * It is a mehod to add the Toolbar with the username and the
 *
 */

- (void) addToolBar {
    
    //Button to select folder to upload
    
    NSString *folderName = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"location", nil), _locationInfo];
    folderName = [[NSString stringWithString:folderName] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [_folderToUploadButton setTitle:folderName];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorOfToolBarButtons];
    shadow.shadowOffset = CGSizeMake(0.5, 0);
    
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [UIColor colorOfToolBarButtons],
                                      NSShadowAttributeName: shadow,
                                      NSFontAttributeName: [UIFont systemFontOfSize:16.0]};
    
    
    [_folderToUploadButton setTitleTextAttributes:titleAttributes forState:UIControlStateNormal];
    
}

///-----------------------------------
/// @name selectFolderToUploadFiles
///-----------------------------------

/**
 * Method to change the folder where we will upload the files
 *
 * @param id - sender
 *
 */
- (IBAction) selectFolderToUploadFiles:(id)sender  {
    SelectFolderViewController *sf = [[SelectFolderViewController alloc]initWithNibName:@"SelectFolderViewController" bundle:nil];
    //sf.toolBarLabelTxt = NSLocalizedString(@"upload_label", nil);
    sf.toolBarLabelTxt = @"";
    
    SelectFolderNavigation *navigation = [[SelectFolderNavigation alloc]initWithRootViewController:sf];
    sf.parent=navigation;
    sf.currentRemoteFolder=self.currentRemoteFolder;
    
    //We get the current folder to create the local tree
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSString *localRootUrlString = [NSString stringWithFormat:@"%@%d/", [UtilsUrls getOwnCloudFilePath],app.activeUser.idUser];
    
    sf.currentLocalFolder = localRootUrlString;
    
    navigation.delegate=self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:navigation animated:YES completion:nil];
        
    } else {
        navigation.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        
        // [self presentViewController:navigation animated:YES completion:nil];
        [self presentViewController:navigation animated:YES completion:nil];
        
    }
    [sf release];
}

#pragma mark Select Folder Navigation Delegate Methods
- (void)folderSelected:(NSString*)folder{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    DLog(@"Change Folder");
    //TODO. Change current Remote Folder
    self.currentRemoteFolder=folder;
    
    NSArray *splitedUrl = [folder componentsSeparatedByString:@"/"];
    // int cont = [splitedUrl count];
    NSString *folderName = [NSString stringWithFormat:@"%@",[splitedUrl objectAtIndex:([splitedUrl count]-2)]];
    
    folderName = [[NSString stringWithString:folderName] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    DLog(@"Folder is:%@", folderName);
    if ([self.currentRemoteFolder isEqualToString:[NSString stringWithFormat:@"%@%@", app.activeUser.url,k_url_webdav_server]]) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        folderName=appName;
    }
    
    self.locationInfo=folderName;
    
    [_folderToUploadButton setTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"location", nil), folderName]];
}
- (void)cancelFolderSelected{
    
    //Nothing
    DLog(@"Cancel folder");
}

@end

