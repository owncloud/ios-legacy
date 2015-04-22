//
//  AppDelegate.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */





#import <UIKit/UIKit.h>
#import "UserDto.h"
#import "MediaViewController.h"
#import "CheckAccessToServer.h"
#import "PrepareFilesToUpload.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FMDatabaseQueue.h"
#import "KKPasscodeViewController.h"
#import "OCTabBarController.h"
#import "DetailViewController.h"
#import "ManageDownloads.h"

#define k_DB_version_1 1
#define k_DB_version_2 2
#define k_DB_version_3 3
#define k_DB_version_4 4
#define k_DB_version_5 5
#define k_DB_version_6 6
#define k_DB_version_7 7
#define k_DB_version_8 8
#define k_DB_version_9 9
#define k_DB_version_10 10
#define k_DB_version_11 11
#define k_DB_version_12 12
#define k_DB_version_13 13

@class MGSplitViewController;
@class FilesViewController;
@class RecentViewController;
@class SettingsViewController;
@class LoginViewController;
@class Download;
@class OCCommunication;
@class UploadFromOtherAppViewController;
@class SharedViewController;
@class ManageFavorites;
@class CheckHasShareSupport;

extern NSString * CloseAlertViewWhenApplicationDidEnterBackground;
extern NSString * RefreshSharesItemsAfterCheckServerVersion;
extern NSString * NotReachableNetworkForUploadsNotification;
extern NSString * NotReachableNetworkForDownloadsNotification;


@interface AppDelegate : UIResponder <UIApplicationDelegate, CheckAccessToServerDelegate, PrepareFilesToUploadDelegate, KKPasscodeViewControllerDelegate> {
  
    
    UserDto *_activeUser;
    
  
    NSMutableArray *_uploadArray;
    NSMutableArray *_webDavArray;
     
    RecentViewController *_recentViewController;
    FilesViewController *_filesViewController;
    //Pointer to a actual files view controller where the user is.
    FilesViewController *_presentFilesViewController;
    //FavouritesViewController *_favouritesViewController;
    SettingsViewController *_settingsViewController;
    //OCTabBarController *_tabBarController;
   
    CheckAccessToServer *_mCheckAccessToServer;
    MGSplitViewController *_splitViewController;  
    DetailViewController *_detailViewController;
    
    UploadFromOtherAppViewController *_uploadFromOtherAppViewController;

    MediaViewController *_mediaPlayer;
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
    BOOL _isErrorLoginShown;
    
    //Flag to force the reload the File List from WebDav
    BOOL _isNecessaryReloadFromWebDav;
    
    //OAuth
    NSString *_oauthToken;
    
    //Queue Database
    NSOperationQueue *_databaseOperationsQueue;
    
    PrepareFilesToUpload *_prepareFiles;
    
    BOOL _isConnectionToTheServerUploadingFiles;
    BOOL _isUploadViewVisible;
    BOOL _isLoadingVisible;
    
    
}

@property (strong, nonatomic) LoginViewController *loginWindowViewController;

- (void) initAppWithEtagRequest:(BOOL)isEtagRequestNecessary;
- (void)presentUploadFromOtherApp;
- (void)updateRecents;
- (void) updateProgressView:(NSUInteger)num withPercent:(float)percent;
- (void) restartAppAfterDeleteAllAccounts;
+ (ALAssetsLibrary *)defaultAssetsLibrary;
+ (FMDatabaseQueue*)sharedDatabase;

/*
 * Method to get a Singleton of the OCCommunication to manage all the communications
 */
+ (OCCommunication*)sharedOCCommunication;


///-----------------------------------
/// @name SharedManageFavorites
///-----------------------------------

/**
 * Method to get a singelton of ManageFavorites
 *
 */
+ (ManageFavorites*)sharedManageFavorites;

- (void)dismissPopover;
- (void)doLoginWithOauthToken;

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
 */
- (void) doThingsThatShouldDoOnStart;

/*
 * Methods to clear network cache
 */
- (void) eraseURLCache;
- (void) eraseCredentials;

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
- (void) cancelTheCurrentUploadsWithTheSameUserId:(NSInteger)idUser;

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
- (void) cancelTheCurrentUploadsOfTheUser:(NSInteger)idUser;

/*
 * This method is called after that this class receive the notification that the user
 * has resolved the credentials error.
 * In this method we changed the kind of error of uploads failed "errorCredentials" to "notAndError"
 * for a specific user
 * @idUser -> idUser for a scpecific user.
 */
- (void)changeTheStatusOfCredentialsFilesErrorOfAnUserId:(NSInteger)idUser;


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

///-----------------------------------
/// @name Check if server support different things
///-----------------------------------

/**
 * This method check if the server support multipple things:
 * - If support Share
 * - If support Cookies
 *
 */
- (void)checkIfServerSupportThings;

//-----------------------------------
/// @name sharedCheckHasShareSupport
///-----------------------------------

/**
 * Singleton to check if a server support share API
 *
 */
+ (CheckHasShareSupport*) sharedCheckHasShareSupport;



@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoginViewController *loginViewController;
@property (strong, nonatomic) UserDto *activeUser;
@property (strong, nonatomic) OCTabBarController *ocTabBarController;
@property (nonatomic, retain) CheckAccessToServer *mCheckAccessToServer;
@property (nonatomic, strong) NSMutableArray *uploadArray;
@property (nonatomic, strong) NSMutableArray *webDavArray;
@property (nonatomic, strong) SharedViewController *sharedViewController;
@property (nonatomic, strong) RecentViewController *recentViewController;
@property (nonatomic, strong) FilesViewController *filesViewController;
@property (nonatomic, strong) FilesViewController *presentFilesViewController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) MGSplitViewController *splitViewController;
@property (nonatomic, strong)DetailViewController *detailViewController;
@property (nonatomic, strong) MediaViewController *mediaPlayer;
@property (nonatomic, strong) UploadFromOtherAppViewController *uploadFromOtherAppViewController;
@property (nonatomic) BOOL isErrorLoginShown;
@property (nonatomic) BOOL firstInit;
@property(nonatomic)BOOL isRefreshInProgress;
@property(nonatomic)  UIBackgroundTaskIdentifier uploadTask;
@property (nonatomic, strong)NSString *filePathFromOtherApp;
@property (nonatomic) BOOL isFileFromOtherAppWaitting;
@property (nonatomic) BOOL isSharedToOwncloudPresent;
@property (nonatomic, strong) NSString *oauthToken;
@property (nonatomic) BOOL isNecessaryReloadFromWebDav;
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
//Know if the uploads has been a expiration time error
@property (nonatomic) BOOL isExpirationTimeInUpload;
//AlertView to control that we do not show the same error multiple times
@property (nonatomic, strong) UIAlertView *downloadErrorAlertView;
@property (copy) void (^backgroundSessionCompletionHandler)();
//Url of the server redirected to be used on uploads in background
@property (nonatomic, strong) NSString *urlServerRedirected;
@property (nonatomic, strong) ManageDownloads *downloadManager;

@end
