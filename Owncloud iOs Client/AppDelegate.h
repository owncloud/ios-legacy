//
//  AppDelegate.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "UserDto.h"
#import "MediaAVPlayerViewController.h"
#import "PrepareFilesToUpload.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FMDatabaseQueue.h"
#import "KKPasscodeViewController.h"
#import "OCTabBarController.h"
#import "DetailViewController.h"
#import "ManageDownloads.h"
#import "CheckAccessToServer.h"
#import "UtilsLogin.h"
#import "OCOAuth2Configuration.h"

@class FilesViewController;
@class RecentViewController;
@class SettingsViewController;
@class HelpGuideViewController;
@class Download;
@class OCCommunication;
@class SyncFolderManager;
@class UploadFromOtherAppViewController;
@class SharedViewController;
@class ManageFavorites;
@class CheckHasShareSupport;
@class CheckCapabilities;

@class UniversalLoginViewController;
@class ManageAccounts;


extern NSString * CloseAlertViewWhenApplicationDidEnterBackground;
extern NSString * RefreshSharesItemsAfterCheckServerVersion;
extern NSString * NotReachableNetworkForUploadsNotification;
extern NSString * NotReachableNetworkForDownloadsNotification;


@interface AppDelegate : UIResponder <UIApplicationDelegate, PrepareFilesToUploadDelegate, KKPasscodeViewControllerDelegate, CheckAccessToServerDelegate> {
  
    
    UserDto *_activeUser;
    
  
    NSMutableArray *_uploadArray; //uploads of type ManageUploadRequest
    NSMutableArray *_webDavArray;
     
    RecentViewController *_recentViewController;
    FilesViewController *_filesViewController;

    //FavouritesViewController *_favouritesViewController;
    SettingsViewController *_settingsViewController;
    //OCTabBarController *_tabBarController;
   
    UISplitViewController *_splitViewController;
    DetailViewController *_detailViewController;
    
    UploadFromOtherAppViewController *_uploadFromOtherAppViewController;

    MediaAVPlayerViewController *_avMoviePlayer;
    float _currentPlayBack;
    
    
    UIWindow *_window;
    
  
    BOOL _firstInit;
    
    
    //For uploads
    //Background task
    UIBackgroundTaskIdentifier uploadTask;
    //Flag to indicate that after the init open shared
    BOOL _isFileFromOtherAppWaitting;
    //FilePath where is the file from other app
    NSString *_filePathFromOtherApp;
    //Flag to indicate that shared to owncloud is present
    BOOL _isSharedToOwncloudPresent;

    //Flag
    BOOL _isRefreshInProgress;
    
    //OAuth
    NSString *_oauthToken;
    
    //Queue Database
    NSOperationQueue *_databaseOperationsQueue;
    
    PrepareFilesToUpload *_prepareFiles;
    
    BOOL _isConnectionToTheServerUploadingFiles;
    BOOL _isUploadViewVisible;
    BOOL _isLoadingVisible;
    
    
}

@property (strong, nonatomic) HelpGuideViewController *helpGuideWindowViewController;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UserDto *activeUser;
@property (strong, nonatomic) OCTabBarController *ocTabBarController;
@property (nonatomic, strong) NSMutableArray *uploadArray;
@property (nonatomic, strong) NSMutableArray *webDavArray;
@property (nonatomic, strong) SharedViewController *sharedViewController;
@property (nonatomic, strong) RecentViewController *recentViewController;
@property (nonatomic, strong) FilesViewController *filesViewController;
//Pointer to a actual files view controller where the user is.
@property (nonatomic, strong) FilesViewController *presentFilesViewController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) UISplitViewController *splitViewController;
@property (nonatomic, strong)DetailViewController *detailViewController;
@property (nonatomic, strong) MediaAVPlayerViewController *avMoviePlayer;
@property (nonatomic, strong) UploadFromOtherAppViewController *uploadFromOtherAppViewController;
@property (nonatomic) BOOL firstInit;
@property(nonatomic)BOOL isRefreshInProgress;
@property(nonatomic)  UIBackgroundTaskIdentifier uploadTask;
@property (nonatomic, strong)NSString *filePathFromOtherApp;
@property (nonatomic) BOOL isFileFromOtherAppWaitting;
@property (nonatomic) BOOL isSharedToOwncloudPresent;
@property (nonatomic, strong) NSString *oauthToken;
@property (nonatomic, strong) PrepareFilesToUpload *prepareFiles;
@property (nonatomic, strong) NSOperationQueue *databaseOperationsQueue;
@property (nonatomic) BOOL isUploadViewVisible;
@property (nonatomic) BOOL isLoadingVisible;
@property (nonatomic) BOOL isPasscodeVisible;
@property (nonatomic, strong) UIViewController *currentViewVisible;
//Flag for detect if a overwrite process is in progress
@property (nonatomic) BOOL isOverwriteProcess;
@property (nonatomic,strong) UserDto *userUploadWithError;
@property (nonatomic) long dateLastRelaunch;
@property (nonatomic) long dateLastCheckingWaiting;
//New user
@property (nonatomic) BOOL isNewUser;
//AlertView to control that we do not show the same error multiple times
@property (nonatomic, strong) UIAlertView *downloadErrorAlertView;
@property (copy) void (^backgroundSessionCompletionHandler)();
//Url of the server redirected to be used on uploads in background
@property (nonatomic, strong) NSString *urlServerRedirected;
@property (nonatomic, strong) ManageDownloads *downloadManager;
@property (nonatomic, strong) NSString *userSessionCurrentToken;

@property (nonatomic, strong) OCOAuth2Configuration *oauth2Configuration;

/*
 * Method to get a Singleton of the OCCommunication to manage all the communications
 */
+ (OCCommunication*)sharedOCCommunication;

/*
* Method to get a Singleton of the OCCommunication to manage the communications to download a folder
*/
+ (OCCommunication*)sharedOCCommunicationDownloadFolder;

/*
 * Method to get a Singleton of the SyncFolderManager to manage the download of a folder process
 */
+ (SyncFolderManager*)sharedSyncFolderManager;

/*
 * Method to get a Singleton of the sharedManageFavorites to manage the favorites
 */
+ (ManageFavorites*)sharedManageFavorites;


- (void) initAppWithEtagRequest:(BOOL)isEtagRequestNecessary;
- (void) presentUploadFromOtherApp;
- (void) updateRecents;
- (void) updateProgressView:(NSUInteger)num withPercent:(float)percent;
- (void) restartAppAfterDeleteAllAccounts;

//Method that erase the data of the detail view in iPad.
- (void)presentWithView;

//Method to show an error if we access to file while etag is refreshing the current folder
- (void)showErrorOnIpadIfIsNecessaryCancelDownload;

//Method that cancel download of the detail view in iPad.
- (void)cancelDonwloadInDetailView;

- (void)errorLogin;

/*
 * Method that receive a file to upload
 */
- (void)itemToUploadFromOtherAppWithName:(NSString*)name andPathName:(NSString*)pathName andRemoteFolder:(NSString*)remFolder andIsNotNeedCheck:(BOOL) isNotNecessaryCheckIfExist;


/*
 * Method that inform if the filePath its playing in media player.
 * @filePath -> file path of the file
 */
- (BOOL)isMediaPlayerRunningWithThisFilePath:(NSString*)filePath;

/*
 * Method that remove media player of the preview the screen
 * and free memory.
 */
- (void)quitMediaPlayer;

/*
 * Method that indicate the app that the player can receive external events
 */
- (void)canPlayerReceiveExternalEvents;

/*
 * Method that indicate the app disable external events
 */
- (void)disableReceiveExternalEvents;

/*
 * Method to do things that should do on start (clean folders, tables...)
 * This method prepare the uploads offline table and the file system to save a number of uploads
 */
- (void) updateStateAndRestoreUploadsAndDownloads;

/*
 * Method relaunch the upload failed if exist
 * This method has a timeout
 *@isForced -> If YES the timeout is 0 secs
 */
- (void) relaunchUploadsFailed:(BOOL)isForced;

/*
 * Method that relaunch upload failed without timeout
 */
- (void) relaunchUploadsFailedForced;

/*
 * Method that relaunch upload failed with timeout
 */
- (void) relaunchUploadsFailedNoForced;

/*
 * Method to remove the files from recents by user
 */
- (void) removeFromTabRecentsAllInfoByUser:(UserDto *)user;

/*
 * This methods is called after that this class receive the notification that the user
 * has resolved the credentials error
 * In this method we changed the credentials in currents uploads
 * for a specific user
 *
 */
- (void) cancelTheCurrentUploadsWithTheSameUserId:(NSInteger)userId;

///-----------------------------------
/// @name Cancel the Currents Uploads
///-----------------------------------

/**
 * This method cancel the currents uploads for a specific user
 * by "Error Credentials"
 *
 * @param userId -> id of user
 *
 */
- (void) cancelTheCurrentUploadsOfTheUser:(NSInteger)userId;

/*
 * This method is called after that this class receive the notification that the user
 * has resolved the credentials error.
 * In this method we changed the kind of error of uploads failed "errorCredentials" to "notAndError"
 * for a specific user
 * @userId -> userId for a scpecific user.
 */
- (void)changeTheStatusOfCredentialsFilesErrorOfAnUserId:(NSInteger)userId;


///-----------------------------------
/// @name Generate App Interface
///-----------------------------------

/**
 * This method generate the app interface
 *
 * For iPhone:
 *    - TabBarController with three items:
 *           - File list
 *           - Recents view
 *           - Settings view
 * For iPad:
 *    - The same TabBarController with three items.
 *    - Detail View.
 *
 */
- (void) generateAppInterfaceFromLoginScreen:(BOOL)isFromLogin;


//-----------------------------------
/// @name reloadTableFromDataBaseIfFileIsVisibleOnList
///-----------------------------------

/**
 * Method that check if the file is visible on the file list before reload the table from the database
 *
 * @param file -> FileDto visible
 */
- (void) reloadTableFromDataBaseIfFileIsVisibleOnList:(FileDto *) file;
- (void) reloadCellByFile:(FileDto *) file;
- (void) reloadCellByUploadOffline:(UploadsOfflineDto *) uploadOffline;
- (void) reloadCellByKey:(NSString *) key;

- (void) initUploadsOffline;
- (void) launchUploadsOfflineFromDocumentProvider;

- (void) launchProcessToSyncAllFavorites;

- (void) showPassCodeIfNeeded;


//---------------------------
/// @name switchActiveUser
///-------------------------

/**
 * Method that switches the active user to that passed as a parameter
 *
 * @param user -> UserDto to set as active user
 * @param isNewAccount -> BOOL if this user is a new account added
 */
- (void) switchActiveUserTo:(UserDto *)user isNewAccount:(BOOL)isNewAccount withCompletionHandler:(void (^)(void)) completionHandler;

@end
