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

- (BOOL) imageInstantUploadEnabled {
    return ACTIVE_USER.imageInstantUpload;
}

- (BOOL) videoInstantUploadEnabled {
    return ACTIVE_USER.videoInstantUpload;
}

- (BOOL) backgroundInstantUploadEnabled {
    return ACTIVE_USER.backgroundInstantUpload;
}

- (void) setImageInstantUploadEnabled:(BOOL)enabled {
    @synchronized (self) {
        if (enabled != self.imageInstantUploadEnabled) {
            if (!self.imageInstantUploadEnabled) {
                [self getMediaLibraryPermission:^(BOOL granted) {
                    if (granted) {
                        ACTIVE_USER.imageInstantUpload = YES;
                        [ManageAppSettingsDB updateImageInstantUploadTo:YES];
                        ACTIVE_USER.timestampInstantUploadImage = [[NSDate date] timeIntervalSince1970];
                        [ManageAppSettingsDB updateTimestampInstantUploadImage:ACTIVE_USER.timestampInstantUploadImage];
                        [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
                        [self attemptUpload];
                    } else {
                        [self showAlertViewWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil) body:NSLocalizedString(@"message_access_photos_not_enabled", nil)];
                        [self.delegate instantUploadPermissionLostOrDenied];
                    }
                }];
            } else{
                ACTIVE_USER.imageInstantUpload = NO;
                [ManageAppSettingsDB updateImageInstantUploadTo:NO];
                if (!self.videoInstantUploadEnabled) {
                    [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
                    [self setBackgroundInstantUploadEnabled:NO];
                }
            }
        }
    }
}

- (void) setVideoInstantUploadEnabled:(BOOL)enabled {
    @synchronized (self) {
        if (enabled != self.videoInstantUploadEnabled) {
            if (!self.videoInstantUploadEnabled) {
                [self getMediaLibraryPermission:^(BOOL granted) {
                    if (granted) {
                        ACTIVE_USER.videoInstantUpload = YES;
                        [ManageAppSettingsDB updateVideoInstantUploadTo:YES];
                        ACTIVE_USER.timestampInstantUploadVideo = [[NSDate date] timeIntervalSince1970];
                        [ManageAppSettingsDB updateTimestampInstantUploadVideo:ACTIVE_USER.timestampInstantUploadVideo];
                        [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
                        [self attemptUpload];
                    } else {
                        [self showAlertViewWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil) body:NSLocalizedString(@"message_access_photos_not_enabled", nil)];
                        [self.delegate instantUploadPermissionLostOrDenied];
                    }
                }];
            } else {
                ACTIVE_USER.videoInstantUpload = NO;
                [ManageAppSettingsDB updateVideoInstantUploadTo:NO];
                if (!self.imageInstantUploadEnabled) {
                    [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
                    [self setBackgroundInstantUploadEnabled:NO];
                }
            }
        }
    }
}

- (void) getMediaLibraryPermission:(void(^)(BOOL granted))completion {
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        if (completion) {
            completion(YES);
        }
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (completion) {
                completion(status == PHAuthorizationStatusAuthorized);
            }
        }];
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
    if (self.imageInstantUploadEnabled || self.videoInstantUploadEnabled) {
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
            [self setImageInstantUploadEnabled:NO];
            [self setVideoInstantUploadEnabled:NO];
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
    @synchronized (self) {
        if (self.imageInstantUploadEnabled || self.videoInstantUploadEnabled) {
            if (ACTIVE_USER.username != nil) {
                if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                    
                    BOOL instantUploadPhotosEnabled = self.imageInstantUploadEnabled;
                    BOOL instantUploadVideosEnabled = self.videoInstantUploadEnabled;
                    
                    PHFetchResult *cameraRollAssetCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
                    
                    NSPredicate * newImagesFetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeImage], [NSPredicate predicateWithFormat:@"creationDate > %@", [NSDate dateWithTimeIntervalSince1970:ACTIVE_USER.timestampInstantUploadImage]]]];
                    NSPredicate * newVideosFetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeVideo], [NSPredicate predicateWithFormat:@"creationDate > %@", [NSDate dateWithTimeIntervalSince1970:ACTIVE_USER.timestampInstantUploadVideo]]]];
                    
                    NSPredicate *newInstantUploadAssetsFetchOptionPredicate;
                    if (instantUploadPhotosEnabled && instantUploadVideosEnabled) {
                        newInstantUploadAssetsFetchOptionPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[newImagesFetchPredicate, newVideosFetchPredicate]];
                    } else if (instantUploadPhotosEnabled) {
                        newInstantUploadAssetsFetchOptionPredicate = newImagesFetchPredicate;
                    } else if (instantUploadVideosEnabled) {
                        newInstantUploadAssetsFetchOptionPredicate = newVideosFetchPredicate;
                    }
                    
                    PHFetchOptions *newInstantUploadAssetsFetchOptions = [PHFetchOptions new];
                    newInstantUploadAssetsFetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
                    newInstantUploadAssetsFetchOptions.predicate = newInstantUploadAssetsFetchOptionPredicate;
                    
                    PHFetchResult *newAssets = [PHAsset fetchAssetsInAssetCollection:cameraRollAssetCollection[0] options:newInstantUploadAssetsFetchOptions];
                    
                    if (newAssets != nil && [newAssets count] != 0) {
                        
                        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        
                        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                        ACTIVE_USER.timestampInstantUploadImage = now;
                        ACTIVE_USER.timestampInstantUploadVideo = now;
                        [ManageAppSettingsDB updateTimestampInstantUploadImage:now];
                        [ManageAppSettingsDB updateTimestampInstantUploadVideo:now];
                        
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
                        
                        [app.prepareFiles addAssetsToUpload:newAssets andRemoteFolder:[[NSString alloc] initWithFormat:@"%@%@/", [UtilsUrls getFullRemoteServerPathWithWebDav:ACTIVE_USER], k_path_instant_upload]];
                    }
                } else {
                    [self setImageInstantUploadEnabled:NO];
                    [self setVideoInstantUploadEnabled:NO];
                    [self showAlertViewWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil) body:NSLocalizedString(@"message_access_photos_not_enabled", nil)];
                    [self.delegate instantUploadPermissionLostOrDenied];
                }
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
