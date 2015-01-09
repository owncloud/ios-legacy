//
//  ManageAsset.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import "ManageAsset.h"

@implementation ManageAsset

-(void)initAssetLibrary{
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];

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
            self.assetGroupCameraRoll = group;
        }
        else if(nType == ALAssetsGroupPhotoStream){
            //Nothing
        }else {
            
        }
        
    };
    
    // Group Enumerator Failure Block
    void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"no_access_to_gallery", nil)
                                                        delegate:nil
                                                        cancelButtonTitle:@"Ok"
                                                        otherButtonTitles:nil];
        [alert show];
        
        DLog(@"A problem occured access camera roll %@", [error description]);
    };

    
    //check authorizationstatus camera roll?
  /*  ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    
    if (status != ALAuthorizationStatusAuthorized) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"Please give this app permission to access your photo library in your settings app!" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        [alert show];
    }*/


    
    DLog(@"enumerating photos");
    [self.assetGroupCameraRoll enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result == nil) {
            return;
        }
        
        OCAsset *ocAsset = [[OCAsset alloc] initWithAsset:result];
        [self.OCAssets addObject:ocAsset];
    }];
    DLog(@"done enumerating photos");
}

@end
