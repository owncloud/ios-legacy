//
//  AlbumPickerController.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAssetSelectionDelegate.h"
#import "SelectFolderNavigation.h"
#import "OCToolBar.h"

@interface ELCAlbumPickerController : UIViewController <ELCAssetSelectionDelegate, UITableViewDataSource, UITableViewDelegate, SelectFolderDelegate>

@property (nonatomic, assign) id<ELCAssetSelectionDelegate> parent;
@property (nonatomic, retain) NSMutableArray *assetGroups;
@property (nonatomic, retain) NSString *currentRemoteFolder;
@property (nonatomic, retain) NSString *locationInfo;
@property (nonatomic, retain) IBOutlet UITableView *albumPickerTableView;
@property (nonatomic, retain) IBOutlet OCToolBar *bottomToolBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *folderToUploadButton;

- (IBAction) selectFolderToUploadFiles:(id)sender;

@end

