//
//  ManageAsset.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import "ManageAsset.h"
#import "ManageAppSettingsDB.h"

@implementation ManageAsset

+ (ManageAsset *)sharedSingleton {
    static ManageAsset *sharedSingleton;
    @synchronized(self)
    {
        if (!sharedSingleton){
            sharedSingleton = [[ManageAsset alloc] init];
        }
        return sharedSingleton;
    }
}

-(void)initAssetLibrary{
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];

    //check authorizationstatus camera roll? //todo localization
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"Please give this app permission to access your photo library in your settings app!" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
       [alert show];
    } else if ([ManageAppSettingsDB isInstantUpload]){
        
        NSDate * startDateInstantUpload = [self getDateStartInstantUpload];

        [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                 usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                     
                                     if (group == nil) {
                                         return;
                                     }
                                     
                                     // added fix for camera albums order
                                     NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                                     NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                                     
                                     if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
                                         self.assetGroupCameraRoll = group;
                                         self.assetsNewToUpload = [self getArrayNewAssetFromGroup:group andDate:startDateInstantUpload];
                                         
                                     }
                                     else if(nType == ALAssetsGroupPhotoStream){
                                         //Nothing
                                     }else {
                                         
                                     }
                                     
                                 } failureBlock:^(NSError *error) {
                                     //todo localization msg
                                     UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                                                      message:NSLocalizedString(@"no_access_to_gallery", nil)
                                                                                     delegate:nil
                                                                            cancelButtonTitle:@"Ok"
                                                                            otherButtonTitles:nil];
                                     [alert show];
                                     
                                     DLog(@"A problem occured access camera roll %@", [error description]);
                                 }];
    }

}

-(NSArray *) getArrayNewAssetFromGroup:(ALAssetsGroup *)group andDate:(NSDate *)dateStart{
    
    DLog(@"sort camera roll");
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                     message:@"launchGetAsset"
                                                    delegate:nil
                                           cancelButtonTitle:@"Ok"
                                           otherButtonTitles:nil];
    [alert show];
    
    NSMutableArray * tmpAssetsNew = [[NSMutableArray alloc] init];
    NSDate * startDate = [self getDateStartInstantUpload];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result == nil) {
            dispatch_semaphore_signal(semaphore);
            return;
        }
        
        OCAsset *asset = [[OCAsset alloc] initWithAsset:result];
        
        //check dates
         //asset. = [result valueForProperty:ALAssetPropertyDate];
        if ([asset.date compare:startDate] == NSOrderedDescending) {
            //assetDate later than startDate
            [tmpAssetsNew addObject:asset];
        }
        
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    
    return [tmpAssetsNew sortedArrayUsingDescriptors:@[sort]];
}

-(NSDate *) getDateStartInstantUpload{
    
    NSDate* dateStart = [NSDate dateWithTimeIntervalSince1970:[ManageAppSettingsDB getDateInstantUpload]];
    
    return dateStart;
}

@end
