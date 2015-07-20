//
//  ManageAsset.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ManageAsset : NSObject

@property (nonatomic, retain) NSMutableArray *assetGroups;

@property (nonatomic, retain) NSMutableArray *allAssetsCameraRoll;

@property (nonatomic, retain) NSArray *assetsNewToUpload;

-(NSArray *)getCameraRollNewItems;
-(void)checkAssetsLibrary;

@end
