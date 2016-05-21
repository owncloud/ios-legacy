//
//  InstantUpload.m
//  Owncloud iOs Client
//
//  Created by Jon Schneider on 5/20/16.
//

#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>

#import "InstantUpload.h"

#import "AppDelegate.h"
#import "constants.h"

#import "ManageAppSettingsDB.h"
#import "ManageUsersDB.h"
#import "UserDto.h"

#define kPhotoLibraryAccessPermissionDeniedAlert [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil) message:NSLocalizedString(@"message_access_photos_not_enabled", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil]

//TODO: Language should be for background upload, not general Instant Upload
#define kLocationAccessAlwaysPermissionDeniedAlert [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_not_enabled", nil) message:NSLocalizedString(@"message_location_not_enabled", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil]

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
        [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleShouldTriggerInstantUpload:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) enabled {
    return [ManageUsersDB getActiveUser].instantUpload;
}

- (BOOL) backgroundInstantUploadEnabled {
    return [ManageUsersDB getActiveUser].backgroundInstantUpload;
}

- (void) setEnabled:(BOOL)enabled {
    if (enabled != self.enabled) {
        if (enabled) {
            if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                [ManageUsersDB getActiveUser].instantUpload = YES;
                [ManageAppSettingsDB updateInstantUploadTo:YES];
                [self attemptUpload];
            } else {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        [self attemptUpload];
                    } else {
                        [kPhotoLibraryAccessPermissionDeniedAlert show];
                        [self.delegate instantUploadPermissionLostOrDenied];
                    }
                }];
            }
        } else {
            [ManageUsersDB getActiveUser].instantUpload = NO;
            [ManageAppSettingsDB updateInstantUploadTo:NO];
            [self setBackgroundInstantUploadEnabled:NO];
        }
    }
}

- (void) setBackgroundInstantUploadEnabled:(BOOL)enabled {
    if (enabled != self.backgroundInstantUploadEnabled) {
        if (enabled) {
            if ([self isBackgroundLocationUpdatesPermissionGranted]) {
                [ManageUsersDB getActiveUser].backgroundInstantUpload = YES;
                [ManageAppSettingsDB updateBackgroundInstantUploadTo:YES];
                [self.locationManager startMonitoringSignificantLocationChanges];
            } else {
                [self.locationManager requestAlwaysAuthorization];
            }
        } else {
            [ManageUsersDB getActiveUser].backgroundInstantUpload = NO;
            [ManageAppSettingsDB updateBackgroundInstantUploadTo:NO];
            [self.locationManager stopMonitoringSignificantLocationChanges];
        }
    }
}

- (void) activate {
    if ([self enabled]) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            [self attemptUpload];
            
            if ([self isBackgroundLocationUpdatesPermissionGranted]) {
                [self.locationManager startMonitoringSignificantLocationChanges];
            } else {
                if ([self backgroundInstantUploadEnabled]) {
                    [self setBackgroundInstantUploadEnabled:NO];
                    [kLocationAccessAlwaysPermissionDeniedAlert show];
                    [self.delegate backgroundInstantUploadPermissionLostOrDenied];
                }
            }
        } else {
            [self setEnabled:NO];
            [kPhotoLibraryAccessPermissionDeniedAlert show];
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
        if ([ManageUsersDB getActiveUser].username != nil) {
            if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                NSArray * newItemsToUpload = @[@"Asset"]; 
                
                NSDate *lastInstantUploadedAssetCaptureDate = [NSDate dateWithTimeIntervalSince1970:[ManageAppSettingsDB getDateInstantUpload]];
                
                PHFetchOptions *newAssetsFetchOptions = [PHFetchOptions new];
                newAssetsFetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
                newAssetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate > %@", lastInstantUploadedAssetCaptureDate];
                
                PHFetchResult *newPhotos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:newAssetsFetchOptions];
                
                if (newPhotos != nil && [newPhotos count] != 0) {
                    
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
                    
                    [app.prepareFiles addAssetsToUpload:newPhotos andRemoteFolder:k_path_instant_upload];
                }
                
            } else {
                [self setEnabled:NO];
                [kPhotoLibraryAccessPermissionDeniedAlert show];
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
            [kLocationAccessAlwaysPermissionDeniedAlert show];
            [self.delegate backgroundInstantUploadPermissionLostOrDenied];
        }
    }
}

#pragma mark PHPhotoLibraryChangeObserver methods

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self attemptUpload];
}

@end
