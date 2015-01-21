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


-(NSArray *)getCameraRollNewItems{
 
    [self checkAssetsLibrary];
    
    return self.assetsNewToUpload;
}

-(void)checkAssetsLibrary{
    
    self.assetsNewToUpload = [[NSMutableArray alloc] init];
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    
    if ([ManageAppSettingsDB isInstantUpload]){
        
        NSDate * startDateInstantUpload = [self getDateStartInstantUpload];

        dispatch_semaphore_t semaphoreGroup = dispatch_semaphore_create(0);
        
        [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                 usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                     
                                     if (group == nil) {
                                         dispatch_semaphore_signal(semaphoreGroup);
                                         return;
                                     }
                                     
                                     NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                                     NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                                     
                                     if (nType == ALAssetsGroupSavedPhotos){
                                         [self.assetGroups addObject:group];
                                         [self.assetsNewToUpload addObjectsFromArray:[self getArrayNewAssetsFromGroup:group andDate:startDateInstantUpload]];
                                     }
                                     
                                 } failureBlock:^(NSError *error) {
                                     UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                                            message:[NSLocalizedString(@"no_access_to_gallery", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName]
                                                                            delegate:nil
                                                                            cancelButtonTitle:@"Ok"
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

-(NSArray *) getArrayNewAssetsFromGroup:(ALAssetsGroup *)group andDate:(NSDate *)dateStart{
    
    DLog(@"get new album assets");

    
    NSMutableArray * tmpAssetsNew = [[NSMutableArray alloc] init];
    //NSMutableArray * tmpAssetsNewImage = [[NSMutableArray alloc] init];

    NSDate * startDate = [self getDateStartInstantUpload];
    NSString *dateString = [NSDateFormatter localizedStringFromDate:startDate
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterFullStyle];
   
    dispatch_semaphore_t semaphoreAsset = dispatch_semaphore_create(0);
    
    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result == nil) {
            dispatch_semaphore_signal(semaphoreAsset);
            return;
        }
        
        OCAsset *asset = [[OCAsset alloc] initWithAsset:result];
        
        //check dates
        if ([asset.date compare:startDate] == NSOrderedDescending) {
            //assetDate later than startDate
            [tmpAssetsNew addObject:asset];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                             message:dateString
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert show];
            DLog(@"asset URL is:%@",[result valueForProperty:ALAssetPropertyURLs]);
          //  UIImage *image = [UIImage imageWithCGImage:[[result defaultRepresentation] fullResolutionImage]];
          //  [tmpAssetsNewImage addObject:image];
        }
        
    }];
    
    while (dispatch_semaphore_wait(semaphoreAsset, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    
    return [tmpAssetsNew sortedArrayUsingDescriptors:@[sort]];
}

-(NSDate *) getDateStartInstantUpload{
    
    NSDate* dateStart = [NSDate dateWithTimeIntervalSince1970:[ManageAppSettingsDB getDateInstantUpload]];
    
    return dateStart;
}

@end
