//
//  ManageAsset.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "OCAsset.h"


@interface ManageAsset : NSObject

@property (nonatomic, retain) ALAssetsGroup *assetGroupCameraRoll;

@property (nonatomic, retain) NSMutableArray *OCAssets;

-(void)initAssetLibrary;
- (NSInteger)numberOfAssets;
- (void)updateArrayAssets;


@end
