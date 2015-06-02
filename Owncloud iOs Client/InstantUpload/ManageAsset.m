//
//  ManageAsset.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import "ManageAsset.h"
#import "ManageAppSettingsDB.h"
#import "UploadUtils.h"
#import <malloc/malloc.h>
@implementation ManageAsset


-(NSArray *)getCameraRollNewItems {
    
    [self checkAssetsLibrary];
    
    return self.assetsNewToUpload;
}

-(void)checkAssetsLibrary {
    
    self.assetsNewToUpload = [[NSMutableArray alloc] init];
    ALAssetsLibrary *assetLibrary = [UploadUtils defaultAssetsLibrary];
    
    if ([ManageAppSettingsDB isInstantUpload]){
        
        dispatch_semaphore_t semaphoreGroup = dispatch_semaphore_create(0);
        
        [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                    usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                        
                                        if (group == nil) {
                                            dispatch_semaphore_signal(semaphoreGroup);
                                            return;
                                        }
                                        
                                        NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                                        
                                        if (nType == ALAssetsGroupSavedPhotos){
                                            [self.assetGroups addObject:group];
                                            self.assetsNewToUpload = [self getArrayNewAssetsFromGroup:group];
                                        }
                                        
                                    } failureBlock:^(NSError *error) {
                                        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil)
                                                                                         message:NSLocalizedString(@"message_access_photos_not_enabled", nil)
                                                                                        delegate:nil
                                                                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                                               otherButtonTitles:nil];
                                        [alert show];
                                        
                                        DLog(@"A problem occured access camera roll %@", [error description]);
                                        
                                        dispatch_semaphore_signal(semaphoreGroup);
                                    }];
        
        while (dispatch_semaphore_wait(semaphoreGroup, DISPATCH_TIME_NOW))
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate distantFuture]];
    }
    
}

-(NSArray *) getArrayNewAssetsFromGroup:(ALAssetsGroup *)group {
    
    DLog(@"get new album assets");
    
    NSMutableArray * tmpAssetsNew = [[NSMutableArray alloc] init];
    
    dispatch_semaphore_t semaphoreAsset = dispatch_semaphore_create(0);
    
    __block long databaseDate = [ManageAppSettingsDB getDateInstantUpload];
    
    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result == nil) {
            dispatch_semaphore_signal(semaphoreAsset);
            return;
        }
        
        long dateAsset = (long)[[result valueForProperty:ALAssetPropertyDate] timeIntervalSince1970];
       // NSLog(@"Size of asset%@: %zd", NSStringFromClass([result class]), malloc_size((__bridge const void *) result));

        DLog(@"Date Database: %ld", databaseDate);
        DLog(@"Date Asset: %ld, index:%d", dateAsset,index);
        
        NSString *assetType = [result valueForProperty:ALAssetPropertyType];
        if ([assetType isEqualToString:@"ALAssetTypePhoto"]) {
            if (dateAsset > databaseDate) {
                //assetDate later than startDate
                [tmpAssetsNew addObject:result];
            } else {
                dispatch_semaphore_signal(semaphoreAsset);
                *stop = YES;
            }
        }
        
    }];
    
    while (dispatch_semaphore_wait(semaphoreAsset, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    
    //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    
    return tmpAssetsNew; //[tmpAssetsNew sortedArrayUsingDescriptors:@[sort]];
}


@end
