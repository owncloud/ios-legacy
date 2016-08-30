//
//  InstantUpload.h
//  Owncloud iOs Client
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>

#import "InstantUpload.h"

#import "AppDelegate.h"
#import "constants.h"

#import "ManageAppSettingsDB.h"
#import "ManageUsersDB.h"
#import "UserDto.h"
#import "UtilsUrls.h"

#define ACTIVE_USER ((AppDelegate *)[[UIApplication sharedApplication] delegate]).activeUser

@interface InstantUpload () <CLLocationManagerDelegate, PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation InstantUpload

+ (instancetype) instantUploadManager {
    static dispatch_once_t once;
    static InstantUpload *__instantUploadManager;
    dispatch_once(&once, ^{
        __instantUploadManager = [[InstantUpload alloc] init];
    });
    return __instantUploadManager;
}

- (instancetype) init {
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleShouldTriggerInstantUpload:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        if (ACTIVE_USER.backgroundInstantUpload && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
            [self setBackgroundInstantUploadEnabled:NO];
        }
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) enabled {
    return ACTIVE_USER.instantUpload;
}

- (BOOL) backgroundInstantUploadEnabled {
    return ACTIVE_USER.backgroundInstantUpload;
}

- (void) setEnabled:(BOOL)enabled {
    @synchronized (self) {
        if (enabled != self.enabled) {
            if (enabled) {
                if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                    ACTIVE_USER.instantUpload = YES;
                    [ManageAppSettingsDB updateInstantUploadTo:YES];
                    ACTIVE_USER.timestampInstantUpload = [[NSDate date] timeIntervalSince1970];;
                    [ManageAppSettingsDB updateTimestampInstantUpload:ACTIVE_USER.timestampInstantUpload];
                    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
                } else {
                    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                        if (status == PHAuthorizationStatusAuthorized) {
                            ACTIVE_USER.instantUpload = YES;
                            [ManageAppSettingsDB updateInstantUploadTo:YES];
                            ACTIVE_USER.timestampInstantUpload = [[NSDate date] timeIntervalSince1970];;
                            [ManageAppSettingsDB updateTimestampInstantUpload:ACTIVE_USER.timestampInstantUpload];
                            [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
                            [self attemptUpload];
                        } else {
                            [self showAlertViewWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil) body:NSLocalizedString(@"message_access_photos_not_enabled", nil)];
                            [self.delegate instantUploadPermissionLostOrDenied];
                        }
                    }];
                }
            } else {
                [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
                ACTIVE_USER.instantUpload = NO;
                [ManageAppSettingsDB updateInstantUploadTo:NO];
                [self setBackgroundInstantUploadEnabled:NO];
            }
        }
    }
}

- (void) setBackgroundInstantUploadEnabled:(BOOL)enabled {
    if (enabled != self.backgroundInstantUploadEnabled) {
        if (enabled) {
            if ([self isBackgroundLocationUpdatesPermissionGranted]) {
                ACTIVE_USER.backgroundInstantUpload = YES;
                [ManageAppSettingsDB updateBackgroundInstantUploadTo:YES];
                [self.locationManager startMonitoringSignificantLocationChanges];
            } else {
                if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                    ACTIVE_USER.backgroundInstantUpload = YES;
                    [ManageAppSettingsDB updateBackgroundInstantUploadTo:YES];
                    [self.locationManager requestAlwaysAuthorization];
                } else {
                    [self showAlertViewWithTitle:NSLocalizedString(@"location_not_enabled", nil) body:NSLocalizedString(@"message_location_not_enabled", nil)];
                    [self.delegate backgroundInstantUploadPermissionLostOrDenied];
                }
            }
        } else {
            ACTIVE_USER.backgroundInstantUpload = NO;
            [ManageAppSettingsDB updateBackgroundInstantUploadTo:NO];
            [self.locationManager stopMonitoringSignificantLocationChanges];
        }
    }
}

- (void) activate {
    if ([self enabled]) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
            [self attemptUpload];
            
            if ([self isBackgroundLocationUpdatesPermissionGranted]) {
                [self.locationManager startMonitoringSignificantLocationChanges];
            } else {
                if ([self backgroundInstantUploadEnabled]) {
                    [self setBackgroundInstantUploadEnabled:NO];
                    [self showAlertViewWithTitle:NSLocalizedString(@"location_not_enabled", nil) body:NSLocalizedString(@"message_location_not_enabled", nil)];
                    [self.delegate backgroundInstantUploadPermissionLostOrDenied];
                }
            }
        } else {
            [self setEnabled:NO];
            [self showAlertViewWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil) body:NSLocalizedString(@"message_access_photos_not_enabled", nil)];
            [self.delegate instantUploadPermissionLostOrDenied];
        }
    }
}

#pragma mark - Instant Upload

- (void) appLifecycleShouldTriggerInstantUpload:(NSNotification *)notification {
    [self attemptUpload];
}

- (void) attemptUpload {
    if ([self enabled]) {
        if (ACTIVE_USER.username != nil) {
            if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                
                NSDate *lastInstantUploadedAssetCaptureDate = [NSDate dateWithTimeIntervalSince1970:ACTIVE_USER.timestampInstantUpload];
                
                PHFetchOptions *newAssetsFetchOptions = [PHFetchOptions new];
                newAssetsFetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
                newAssetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate > %@", lastInstantUploadedAssetCaptureDate];
                
                PHFetchResult *cameraRollAssetCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
                
                PHFetchResult *newPhotos = [PHAsset fetchAssetsInAssetCollection:cameraRollAssetCollection[0] options:newAssetsFetchOptions];
                
                if (newPhotos != nil && [newPhotos count] != 0) {
                    
                    for (PHAsset *image in newPhotos) {
                        NSTimeInterval assetCreatedDate = [image.creationDate timeIntervalSince1970];
                        if (assetCreatedDate > ACTIVE_USER.timestampInstantUpload) {
                            ACTIVE_USER.timestampInstantUpload = assetCreatedDate;
                            [ManageAppSettingsDB updateTimestampInstantUpload:assetCreatedDate];
                        }
                    }
                    
                    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    
                    if (app.prepareFiles == nil) {
                        app.prepareFiles = [[PrepareFilesToUpload alloc] init];
                        app.prepareFiles.listOfFilesToUpload = [[NSMutableArray alloc] init];
                        app.prepareFiles.listOfAssetsToUpload = [[NSMutableArray alloc] init];
                        app.prepareFiles.arrayOfRemoteurl = [[NSMutableArray alloc] init];
                        app.prepareFiles.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
                    }
                    
                    app.prepareFiles.delegate = app;
                    app.prepareFiles.counterUploadFiles = 0;
                    app.uploadTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                        // If you’re worried about exceeding 10 minutes, handle it here
                        
                    }];
                    
                    [app.prepareFiles addAssetsToUpload:newPhotos andRemoteFolder:[[NSString alloc] initWithFormat:@"%@%@/",[UtilsUrls getFullRemoteServerPathWithWebDav:ACTIVE_USER], k_path_instant_upload]];
                }
                
            } else {
                [self setEnabled:NO];
                [self showAlertViewWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil) body:NSLocalizedString(@"message_access_photos_not_enabled", nil)];
                [self.delegate instantUploadPermissionLostOrDenied];
            }
        }
    }
}

#pragma mark - Background Instant Upload

- (BOOL) isBackgroundLocationUpdatesPermissionGranted {
    if ([CLLocationManager locationServicesEnabled]) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            return YES;
        }
    }
    return NO;
}

#pragma mark CLLocationManagerDelegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self attemptUpload];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self backgroundInstantUploadEnabled]) {
        if (status == kCLAuthorizationStatusAuthorizedAlways) {
            [self.locationManager startMonitoringSignificantLocationChanges];
        } else {
            [self setBackgroundInstantUploadEnabled:NO];
            [self showAlertViewWithTitle:NSLocalizedString(@"location_not_enabled", nil) body:NSLocalizedString(@"message_location_not_enabled", nil)];
            [self.delegate backgroundInstantUploadPermissionLostOrDenied];
        }
    }
}

#pragma mark PHPhotoLibraryChangeObserver methods

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self attemptUpload];
}

#pragma mark - Utility

- (void) showAlertViewWithTitle:(NSString *)title body:(NSString *)body{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [alertView show];
    });
}

@end
