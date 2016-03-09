//
//  ManageAsset.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

/*
 Copyright (C) 2015, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ManageAsset : NSObject

@property (nonatomic, retain) NSMutableArray *assetGroups;

@property (nonatomic, retain) NSMutableArray *allAssetsCameraRoll;

@property (nonatomic, retain) NSArray *assetsNewToUpload;

-(NSArray *)getCameraRollNewItems;
-(void)checkAssetsLibrary;

@end
