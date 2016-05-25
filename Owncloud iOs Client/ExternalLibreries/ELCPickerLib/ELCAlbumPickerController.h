//
//  AlbumPickerController.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAssetSelectionDelegate.h"
#import "ELCAssetPickerFilterDelegate.h"
#import "SelectFolderNavigation.h"
#import "OCToolBar.h"

@interface ELCAlbumPickerController : UIViewController <ELCAssetSelectionDelegate, UITableViewDataSource, UITableViewDelegate, SelectFolderDelegate>

@property (nonatomic, weak) id<ELCAssetSelectionDelegate> parent;
@property (nonatomic, strong) NSMutableArray *assetGroups;
@property (nonatomic, strong) NSArray *mediaTypes;
@property (nonatomic, retain) NSString *currentRemoteFolder;
@property (nonatomic, retain) NSString *locationInfo;
@property (nonatomic, retain) IBOutlet UITableView *albumPickerTableView;
@property (nonatomic, retain) IBOutlet OCToolBar *bottomToolBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *folderToUploadButton;

// optional, can be used to filter the assets displayed
@property (nonatomic, weak) id<ELCAssetPickerFilterDelegate> assetPickerFilterDelegate;

@end

