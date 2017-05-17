//
//  AppDelegate.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "AppDelegate.h"
#import "FilesViewController.h"
#import "SettingsViewController.h"
#import "RecentViewController.h"
#import "CheckAccessToServer.h"
#import "DetailViewController.h"
#import "constants.h"
#import "LoginViewController.h"
#import "UploadFromOtherAppViewController.h"
#import "AuthenticationDbService.h"
#import "RetrieveRefreshAndAccessTokenTask.h"
#import "Download.h"
#import "EditAccountViewController.h"
#import "UIColor+Constants.h"
#import "Customization.h"
#import "FMDatabaseQueue.h"
#import "ManageDB.h"
#import "ManageUsersDB.h"
#import "ManageAppSettingsDB.h"
#import "ManageUploadsDB.h"
#import "UploadsOfflineDto.h"
#import "UploadUtils.h"
#import "OCNavigationController.h"
#import "OCPortraitNavigationViewController.h"
#import "OCCommunication.h"
#import "OCURLSessionManager.h"
#import "ImageUtils.h"
#import "PassthroughView.h"
#import "NSString+Encoding.h"
#import "ManageFilesDB.h"
#import "SharedViewController.h"
#import "ManageFavorites.h"
#import "OCErrorMsg.h"
#import "OCFrameworkConstants.h"
#import "UtilsDtos.h"
#import "UtilsUrls.h"
#import "OCKeychain.h"
#import "OCSplitViewController.h"
#import "InitializeDatabase.h"
#import "HelpGuideViewController.h"
#import "SyncFolderManager.h"
#import "DownloadFileSyncFolder.h"
#import "CheckFeaturesSupported.h"
#import "ManageTouchID.h"
#import "InstantUpload.h"
#import "DownloadUtils.h"
#import "UtilsFileSystem.h"
#import "OCKeychain.h"
#import "UtilsCookies.h"

NSString * CloseAlertViewWhenApplicationDidEnterBackground = @"CloseAlertViewWhenApplicationDidEnterBackground";
NSString * RefreshSharesItemsAfterCheckServerVersion = @"RefreshSharesItemsAfterCheckServerVersion";
NSString * NotReachableNetworkForUploadsNotification = @"NotReachableNetworkForUploadsNotification";
NSString * NotReachableNetworkForDownloadsNotification = @"NotReachableNetworkForDownloadsNotification";

@implementation AppDelegate

@synthesize window = _window;
@synthesize loginViewController = _loginViewController;
@synthesize uploadArray=_uploadArray;
@synthesize webDavArray=_webDavArray;
@synthesize recentViewController=_recentViewController;
@synthesize filesViewController=_filesViewController;
@synthesize settingsViewController=_settingsViewController;
@synthesize splitViewController=_splitViewController;
@synthesize detailViewController=_detailViewController;
@synthesize uploadFromOtherAppViewController = _uploadFromOtherAppViewController;
@synthesize uploadTask;
@synthesize filePathFromOtherApp=_filePathFromOtherApp;
@synthesize isFileFromOtherAppWaitting=_isFileFromOtherAppWaitting;
@synthesize isSharedToOwncloudPresent=_isSharedToOwncloudPresent;
@synthesize presentFilesViewController=_presentFilesViewController;
@synthesize isRefreshInProgress=_isRefreshInProgress;
@synthesize oauthToken = _oauthToken;
@synthesize avMoviePlayer=_avMoviePlayer;
@synthesize firstInit=_firstInit;
@synthesize activeUser=_activeUser;
@synthesize prepareFiles=_prepareFiles;
@synthesize databaseOperationsQueue = _databaseOperationsQueue;
@synthesize isUploadViewVisible = _isUploadViewVisible;
@synthesize isLoadingVisible = _isLoadingVisible;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //init
    DLog(@"Init");
    
    self.oauthToken = @"";
    
    if(k_have_image_background_navigation_bar) {
        UIImage *image = [UIImage imageNamed:@"topBar.png"];
        [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
    
    //Database queue
    _databaseOperationsQueue =[[NSOperationQueue alloc] init];
    [_databaseOperationsQueue setMaxConcurrentOperationCount:1];
   
    //Network operation array
    _uploadArray=[[NSMutableArray alloc]init];
    _webDavArray=[[NSMutableArray alloc]init];
    
    self.downloadManager = [ManageDownloads singleton];

    //Init variable
    _isFileFromOtherAppWaitting = NO;
    _isSharedToOwncloudPresent = NO;
    _isRefreshInProgress = NO;
    _firstInit = YES;
    _isLoadingVisible = NO;
    _isOverwriteProcess = NO; //Flag for detect if a overwrite process is in progress
    _isPasscodeVisible = NO;
    _isNewUser = NO;
    
    [self moveIfIsNecessaryFilesAfterUpdateAppFromTheOldFolderArchitecture];
    
    [self moveIfIsNecessaryFolderOfOwnCloudFromContainerAppSandboxToAppGroupSanbox];
    
    //Configuration UINavigation Bar apperance
    [self setUINavigationBarApperanceForNativeMail];
    
    //Init and update the DataBase
    [InitializeDatabase initDataBase];
    
    if (![ManageUsersDB existAnyUser]) {
        //Reset all keychain items when db need to be updated or when db first init after app has been removed and reinstalled
        [OCKeychain resetKeychain];
        
    }
    
    [self showSplashScreenFake];
    
    //Check if the server support shared api
    [CheckFeaturesSupported updateServerFeaturesAndCapabilitiesOfActiveUser];
    
    //Needed to use on background tasks
    if (!k_is_sso_active) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
    
    //Add observer for notifications about network not reachable in uploads
  // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeUploadsToWaitingForServerConnection) name:NotReachableNetworkForUploadsNotification object:nil];
    
   //Allow Notifications iOS8
  /*  if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
   */
    
    //Ugly solution for erase the persistent cache across launches
    
    NSInteger memory = 4; //4 MB
    
    NSUInteger cacheSizeMemory = memory*1024*1024;
    NSUInteger cacheSizeDisk = memory*1024*1024;
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];
    sleep(1); //Important sleep. Very ugly but neccesarry.
    
    UserDto *user = [ManageUsersDB getActiveUser];
    
    if (user) {
        self.activeUser = user;
        
        ((CheckAccessToServer*)[CheckAccessToServer sharedManager]).delegate = self;
        [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:user.url withTimeout:k_timeout_fast];
        
        //if we are migrating url not relaunch sync
        if (![UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:self.activeUser.predefinedUrl]) {
            //Update favorites files if there are active user
            [self performSelector:@selector(launchProcessToSyncAllFavorites) withObject:nil afterDelay:5.0];
        }
        
    } else if (k_show_main_help_guide && [ManageDB getShowHelpGuide]) {
            self.helpGuideWindowViewController = [HelpGuideViewController new];
            self.window.rootViewController = self.helpGuideWindowViewController;
    } else {
        
        [self checkIfIsNecesaryShowPassCode];
    }

    //Show TouchID dialog if active
    if([ManageAppSettingsDB isTouchID]) {
        [[ManageTouchID sharedSingleton] showTouchIDAuth];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:user.predefinedUrl]) {
            [[InstantUpload instantUploadManager] activate];
        }
    });
    
    //Set up user agent, so this way all UIWebView will use it
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[UtilsUrls getUserAgent], @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

    return YES;
}



///-----------------------------------
/// @name Set UINavBar Apperance for native mail
///-----------------------------------

/**
 * This method set the UINavBar Apperance like the custom UINavBar of OCNavigationController in the app
 * in order to use this in the native features like send a mail from our app
 *
 * @warning iOS 6.0 doen't support [UINavigation Bar appearance]
 */
-(void)setUINavigationBarApperanceForNativeMail {
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorOfNavigationBar]];
    
    [[UINavigationBar appearance] setBackgroundImage:[ImageUtils imageWithColor:[UIColor colorOfNavigationBar]] forBarMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorOfNavigationItems]];
    
    //Set the title color
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorOfNavigationTitle];
    shadow.shadowOffset = CGSizeMake(0.5, 0);
    
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [UIColor colorOfNavigationTitle],
                                      NSShadowAttributeName: shadow,
                                      NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0]};
    
    
    [[UINavigationBar appearance] setTitleTextAttributes:titleAttributes];

}

/*
 * Method called from iOS system to send a file from other app.
 */

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation {
    
    //OAuth
    AuthenticationDbService *dbService = [AuthenticationDbService sharedInstance];
    NSString *scheme = [dbService getScheme];
    
    if ([[ url scheme] isEqualToString:scheme] ) {
        if (dbService.isDebugLogEnabled) {
            DLog(@"found %@", scheme);
        }
        AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
        NSString *text = [url absoluteString];
        
        if ([[ dbService getResponseType] isEqualToString:@"code"]) {
            if (dbService.isTraceLogEnabled) {
                DLog(@"Response type = code");
            }
            NSArray *param_s = [text componentsSeparatedByString:@"?"];
            
            if (param_s.count > 1) {
                NSString *param_1 = [param_s objectAtIndex:1];
                
                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                NSArray *parameters = [param_1 componentsSeparatedByString:@"&"];
                for (NSString *parameter in parameters)
                {
                    NSArray *parts = [parameter componentsSeparatedByString:@"="];
                    NSString *key = [[parts objectAtIndex:0] stringByRemovingPercentEncoding];
                    if ([parts count] > 1)
                    {
                        id value = [[parts objectAtIndex:1] stringByRemovingPercentEncoding];
                        [result setObject:value forKey:key];
                    }
                }
                if (dbService.isDebugLogEnabled) {
                    DLog(@"code = %@", [result objectForKey:@"code"]);
                    self.oauthToken = [result objectForKey:@"code"];
                }
                AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
                [dbService setAuthorizationCode:[result objectForKey:@"code"]];
                
                RetrieveRefreshAndAccessTokenTask *task = [[RetrieveRefreshAndAccessTokenTask alloc] init];
                [task executeRetrieveTask];
            }
        }
    } else {
        DLog(@"URL from %@ application", sourceApplication);
        DLog(@"the path is: %@", url.path);
        
        
        //Create File Path
        NSArray *splitedUrl = [url.path componentsSeparatedByString:@"/"];
        NSString *fileName = [NSString stringWithFormat:@"%@",[splitedUrl objectAtIndex:([splitedUrl count]-1)]];
        NSString *filePath;
        
        //We have a bug on iOS8 that can not upload a file on background from Documents/Inbox. So we move the file to the getTempFolderForUploadFiles
        [[NSFileManager defaultManager]moveItemAtPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Inbox"] stringByAppendingPathComponent:fileName] toPath:[[UtilsUrls getTempFolderForUploadFiles] stringByAppendingPathComponent:fileName] error:nil];

        filePath = [[UtilsUrls getTempFolderForUploadFiles] stringByAppendingPathComponent:fileName];
        
        _filePathFromOtherApp=filePath;
        
        DLog(@"File path: %@", filePath);
        
        if (_activeUser.username==nil) {
             _activeUser = [ManageUsersDB getActiveUser];
        }
        
        //_firstInit don't works yet
        if (_activeUser.username==nil || [ManageAppSettingsDB isPasscode] || _isLoadingVisible==YES) {
            //Deleta file
            //[[NSFileManager defaultManager] removeItemAtPath: filePath error: nil];
            _isFileFromOtherAppWaitting=YES;
        }else{
           // [self presentUploadFromOtherApp];
            [self performSelector:@selector(presentUploadFromOtherApp) withObject:nil afterDelay:0.5];
        }
    }
    
    return YES;
}

/*
 * Begin with the screen to upload a file from other app
 */

- (void)presentUploadFromOtherApp{
    
    _isSharedToOwncloudPresent=YES;
    _isFileFromOtherAppWaitting=NO;
    
    //Show file to upload
    _uploadFromOtherAppViewController = [[UploadFromOtherAppViewController alloc]initWithNibName:@"UploadFromOtherAppViewController" bundle:nil];
    
    OCNavigationController *uploadFromOtherAppNavigationController = [[OCNavigationController alloc]initWithRootViewController:_uploadFromOtherAppViewController];
    
    
    _uploadFromOtherAppViewController.filePath=_filePathFromOtherApp;
    if (_filesViewController.folderView) {
        [_filesViewController.folderView dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    
    if (IS_IPHONE) {
        //Remove Controllers
        [_ocTabBarController dismissViewControllerAnimated:NO completion:nil];
        [_ocTabBarController presentViewController:uploadFromOtherAppNavigationController animated:YES completion:nil];
    } else {
        uploadFromOtherAppNavigationController.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        uploadFromOtherAppNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [_splitViewController dismissViewControllerAnimated:NO completion:nil];
        [_splitViewController presentViewController:uploadFromOtherAppNavigationController animated:YES completion:nil];

    }

}

- (void) initAppWithEtagRequest:(BOOL)isEtagRequestNecessary {
    
    [[AppDelegate sharedSyncFolderManager] setThePermissionsOnDownloadCacheFolder];
    
    NSString *localTempPath = [UtilsUrls getTempFolderForUploadFiles];
    [DownloadUtils setThePermissionsForFolderPath:localTempPath];
    
    //First Call when init the app
     self.activeUser = [ManageUsersDB getActiveUserWithoutUserNameAndPassword];
    
    //if is null we do not have any active user on the database
    if(!self.activeUser) {
        
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        self.loginViewController = [[LoginViewController alloc] initWithLoginMode:LoginModeCreate];
        
        self.window.rootViewController = self.loginViewController;
        [self.window makeKeyAndVisible];
        
        
    } else {
        
        [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:self.activeUser.url];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // if we are migrating the url no relaunch pending uploads
            if (![UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:self.activeUser.predefinedUrl]) {
                [self updateStateAndRestoreUploadsAndDownloads];
                [self launchUploadsOfflineFromDocumentProvider];
            }
            
            [self generateAppInterfaceFromLoginScreen:NO];
        });
    }
}

- (void) doLoginWithOauthToken {
    
    if (_activeUser.username==nil) {
        _activeUser=[ManageUsersDB getActiveUser];
    }    
    
    if(_activeUser.idUser > 0) {
        _activeUser.password = self.oauthToken;
        
        //update keychain user
        if(![OCKeychain updateCredentialsById:[NSString stringWithFormat:@"%ld", (long)_activeUser.idUser] withUsername:_activeUser.username andPassword:_activeUser.password]) {
            DLog(@"Error updating credentials of userId:%ld on keychain",(long)_activeUser.idUser);
        }
        
        [UtilsCookies eraseCredentialsAndUrlCacheOfActiveUser];
        
        [self initAppWithEtagRequest:NO];
    } else {
        self.loginViewController.usernameTextField = [[UITextField alloc] init];
        self.loginViewController.usernameTextField.text = @"OAuth";
        
        self.loginViewController.passwordTextField = [[UITextField alloc] init];
        self.loginViewController.passwordTextField.text = self.oauthToken;
        
        [self.loginViewController goTryToDoLogin];
    }
    
}


+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
        
    });
    return library;
}

- (void) restartAppAfterDeleteAllAccounts {
    DLog(@"Restart After Delete All Accounts");
    
    if (_filesViewController.alert) {
        [_filesViewController.alert dismissWithClickedButtonIndex:0 animated:NO];
        _filesViewController.alert = nil;
    }
    
    self.loginWindowViewController = [[LoginViewController alloc] initWithLoginMode:LoginModeCreate];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.window.rootViewController = self.loginWindowViewController;
    [self.window makeKeyAndVisible];
}

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
- (void) generateAppInterfaceFromLoginScreen:(BOOL)isFromLogin{
    
    self.activeUser = [ManageUsersDB getActiveUserWithoutUserNameAndPassword];
    
    NSString *wevDavString = [UtilsUrls getFullRemoteServerPathWithWebDav:_activeUser];
    NSString *localSystemPath = nil;
    
    //Check if we generate the interface from login screen or not
    if (isFromLogin) {
        //From login screen we create the user folder to haver multiuser
        localSystemPath = [NSString stringWithFormat:@"%@%ld/",[UtilsUrls getOwnCloudFilePath],(long)_activeUser.idUser];
        //DLog(@"current: %@", localSystemPath);
        
        //If not exist we create
        if (![[NSFileManager defaultManager] fileExistsAtPath:localSystemPath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:localSystemPath withIntermediateDirectories:NO attributes:nil error:&error];
            //DLog(@"Error: %@", [error localizedDescription]);
        }
        
    } else {
        //We get the current folder to create the local tree
        localSystemPath = [NSString stringWithFormat:@"%@%ld/", [UtilsUrls getOwnCloudFilePath],(long)_activeUser.idUser];
        //DLog(@"localRootUrlString: %@", localSystemPath);
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.window) {
            self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        }
        
        //if ocTabBarController exist remove all of them
        if (_ocTabBarController) {
            [_filesViewController.navigationController popToRootViewControllerAnimated:NO];
            [_recentViewController.navigationController popToRootViewControllerAnimated:NO];
            [_sharedViewController.navigationController popToRootViewControllerAnimated:NO];
            [_settingsViewController.navigationController popToRootViewControllerAnimated:NO];
            
            //liberate controllers
            _filesViewController = nil;
            _recentViewController = nil;
            _sharedViewController = nil;
            _settingsViewController = nil;
            
            //liberate controllers of splitview controller
            if (_splitViewController) {
                _splitViewController = nil;
                _detailViewController = nil;
            }
        }
        
        //Create view controllers and custom navigation controllers
        
        _filesViewController = [[FilesViewController alloc] initWithNibName:@"FilesViewController" onFolder:wevDavString andFileId:0 andCurrentLocalFolder:localSystemPath];
        _filesViewController.isEtagRequestNecessary = YES;
        OCNavigationController *filesNavigationController = [[OCNavigationController alloc]initWithRootViewController:_filesViewController];
        
        _recentViewController = [[RecentViewController alloc]initWithNibName:@"RecentViewController" bundle:nil];
        OCNavigationController *recentsNavigationController = [[OCNavigationController alloc]initWithRootViewController:_recentViewController];
        
        _sharedViewController = [[SharedViewController alloc]initWithNibName:@"SharedViewController" bundle:nil];
        OCNavigationController *sharedNavigationController = [[OCNavigationController alloc]initWithRootViewController:_sharedViewController];
        
        _settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
        OCNavigationController *settingsNavigationController = [[OCNavigationController alloc]initWithRootViewController:_settingsViewController];
        
        UIImage *tabBarImageSelected = [UIImage imageNamed:@"TABfiles.png"];
        UIImage *tabBarRecentSelected = [UIImage imageNamed:@"TABrecents.png"];
        UIImage *tabBarSharedSelected = [UIImage imageNamed:@"TABShares.png"];
        UIImage *tabBarSettingSelected = [UIImage imageNamed:@"TABsettings.png"];
        
        //Set the selected and unselected images
        if (k_is_customize_unselectedUITabBarItems) {
            
            UIImage *tabBarImageUnselected = [tabBarImageSelected imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            filesNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:tabBarImageUnselected selectedImage:tabBarImageSelected];
            
            UIImage *tabBarRecentUnselected = [tabBarRecentSelected imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            recentsNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:tabBarRecentUnselected selectedImage:tabBarRecentSelected];
            
            UIImage *tabBarSharedUnselected = [tabBarSharedSelected imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            sharedNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:tabBarSharedUnselected selectedImage:tabBarSharedSelected];
            
            UIImage *tabBarSettingUnselected = [tabBarSettingSelected imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            settingsNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:tabBarSettingUnselected selectedImage:tabBarSettingSelected];
            
        } else {
            filesNavigationController.tabBarItem.image = tabBarImageSelected;
            recentsNavigationController.tabBarItem.image = tabBarRecentSelected;
            sharedNavigationController.tabBarItem.image = tabBarSharedSelected;
            settingsNavigationController.tabBarItem.image = tabBarSettingSelected;
        }
        
        //Set titles
        filesNavigationController.tabBarItem.title = NSLocalizedString(@"files_tab", nil);
        recentsNavigationController.tabBarItem.title = NSLocalizedString(@"uploads_tab", nil);
        sharedNavigationController.tabBarItem.title = NSLocalizedString(@"shared_tab", nil);
        settingsNavigationController.tabBarItem.title = NSLocalizedString(@"settings", nil);
        
        
        //Create custom tab bar controllers
        _ocTabBarController = [OCTabBarController new];
        _ocTabBarController.viewControllers = [NSArray arrayWithObjects:filesNavigationController, recentsNavigationController, sharedNavigationController, settingsNavigationController, nil];
        
        //Depend of type of device there are differents rootViewController
        if (IS_IPHONE){
            //iPhone
            
            //Assign the tabBarController to the window
            self.window.rootViewController = _ocTabBarController;
            [self.window makeKeyAndVisible];
            //Select the first item of the tabBar
            self.ocTabBarController.selectedIndex = 0;
        } else {
            //iPad
            
            //Create a splitViewController (Split container to show two view in the same time)
            self.splitViewController = [OCSplitViewController new];
            
            self.splitViewController.view.backgroundColor = [UIColor blackColor];
            
            //Create the detailViewController (Detail View of the split)
            self.detailViewController = [[DetailViewController alloc]initWithNibName:@"DetailView" bundle:nil];
            
            //Assign tabBarController like a master view
            
            self.splitViewController.viewControllers = [NSArray arrayWithObjects:self.ocTabBarController, self.detailViewController, nil];
            self.splitViewController.delegate = self.detailViewController;
            
            
            // Add the split view controller's view to the window and display.
            self.window.rootViewController = _splitViewController;
            [self.window makeKeyAndVisible];
            self.ocTabBarController.selectedIndex = 0;
            
            [self.detailViewController performSelector:@selector(configureView) withObject:nil afterDelay:0];
            
        }
        
        self.activeUser = [ManageUsersDB getActiveUser];
        
        //if is file from other app wainting, present the upload from other app view
        if (self.isFileFromOtherAppWaitting==YES) {
            [self presentUploadFromOtherApp];
        }
        
        //Check the version of the server to know if has shared support
        [CheckFeaturesSupported updateServerFeaturesAndCapabilitiesOfActiveUser];
    });
    
}

#pragma mark - OCCommunications
+ (OCCommunication*)sharedOCCommunication
{
	static OCCommunication* sharedOCCommunication = nil;
	if (sharedOCCommunication == nil)
	{
		
        NSURLSessionConfiguration *configuration = nil;
        
        if (k_is_sso_active || !k_is_background_active) {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        } else {
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_session_name];
        }

        configuration.HTTPMaximumConnectionsPerHost = 1;
        configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        configuration.timeoutIntervalForRequest = k_timeout_upload;
        configuration.sessionSendsLaunchEvents = YES;
        [configuration setAllowsCellularAccess:YES];
        OCURLSessionManager *uploadSessionManager = [[OCURLSessionManager alloc] initWithSessionConfiguration:configuration];
        [uploadSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        [uploadSessionManager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition (NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential) {
            return NSURLSessionAuthChallengePerformDefaultHandling;
        }];
        
        NSURLSessionConfiguration *configurationDownload = nil;
        
        if (k_is_sso_active || !k_is_background_active) {
            configurationDownload = [NSURLSessionConfiguration defaultSessionConfiguration];
        } else {
            configurationDownload = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_download_session_name];
        }
     
        configurationDownload.HTTPMaximumConnectionsPerHost = 1;
        configurationDownload.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        configurationDownload.timeoutIntervalForRequest = k_timeout_upload;
        configurationDownload.sessionSendsLaunchEvents = YES;
       [configurationDownload setAllowsCellularAccess:YES];
        OCURLSessionManager *downloadSessionManager = [[OCURLSessionManager alloc] initWithSessionConfiguration:configurationDownload];
        [downloadSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        [downloadSessionManager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition (NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential) {
            return NSURLSessionAuthChallengePerformDefaultHandling;
        }];
        
        NSURLSessionConfiguration *networkConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        networkConfiguration.HTTPShouldUsePipelining = YES;
        networkConfiguration.HTTPMaximumConnectionsPerHost = 1;
        networkConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        OCURLSessionManager *networkSessionManager = [[OCURLSessionManager alloc] initWithSessionConfiguration:networkConfiguration];
        [networkSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        networkSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
   
        sharedOCCommunication = [[OCCommunication alloc] initWithUploadSessionManager:uploadSessionManager andDownloadSessionManager:downloadSessionManager andNetworkSessionManager:networkSessionManager];
        
        //Cookies is allways available in current supported Servers
        sharedOCCommunication.isCookiesAvailable = YES;

	}
	return sharedOCCommunication;
}

+ (OCCommunication*)sharedOCCommunicationDownloadFolder {
    static OCCommunication* sharedOCCommunicationDownloadFolder = nil;
    if (sharedOCCommunicationDownloadFolder == nil) {

        NSURLSessionConfiguration *configurationDownload = nil;
        
        if (k_is_sso_active || !k_is_background_active) {
            configurationDownload = [NSURLSessionConfiguration defaultSessionConfiguration];
        } else {
            configurationDownload = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_download_folder_session_name];
        }
        
        configurationDownload.HTTPMaximumConnectionsPerHost = 1;
        configurationDownload.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        configurationDownload.timeoutIntervalForRequest = k_timeout_upload;
        configurationDownload.sessionSendsLaunchEvents = YES;
        [configurationDownload setAllowsCellularAccess:YES];
        OCURLSessionManager *downloadSessionManager = [[OCURLSessionManager alloc] initWithSessionConfiguration:configurationDownload];
        
        sharedOCCommunicationDownloadFolder = [[OCCommunication alloc] initWithUploadSessionManager:nil andDownloadSessionManager:downloadSessionManager andNetworkSessionManager:nil];
        
        //Cookies is allways available in current supported Servers
        sharedOCCommunicationDownloadFolder.isCookiesAvailable = YES;
        
    }
    return sharedOCCommunicationDownloadFolder;
}

+ (SyncFolderManager*)sharedSyncFolderManager {
    
    static SyncFolderManager* sharedSyncFolderManager = nil;
    
    if (sharedSyncFolderManager == nil) {
        sharedSyncFolderManager = [[SyncFolderManager alloc] init];
    }
    
    return sharedSyncFolderManager;
}

+ (ManageFavorites*)sharedManageFavorites {
    
    static ManageFavorites* manageFavorites = nil;
    
    if (manageFavorites == nil) {
        manageFavorites = [[ManageFavorites alloc] init];
    }
    
    return manageFavorites;
}


#pragma mark - ManageFavorites

/*
 * This method is for launch the syncAllFavoritesOfUser in background
 */
- (void) launchProcessToSyncAllFavorites {
    
    //Do operations in background thread
    [[AppDelegate sharedManageFavorites] syncAllFavoritesOfUser:self.activeUser.idUser];
    
}

#pragma mark - DetailViewController Methods for iPad

- (void)cancelDonwloadInDetailView{
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.detailViewController didPressCancelButton:nil];
        
        if (self.detailViewController.galleryView) {
            //cancel download and quit loading
            if ([self.detailViewController.galleryView isCurrentImageDownloading]) {
                //self.detailViewController.galleryView.loadingSpinner.hidden=YES;
                [self.downloadManager cancelDownloads];
                [self.detailViewController presentWhiteView];
            }
        }
    }
    
}


- (void)presentWithView{
    [self.detailViewController presentWhiteView];
}

- (void)showErrorOnIpadIfIsNecessaryCancelDownload{
    [self.detailViewController showErrorOnIpadIfIsNecessaryCancelDownload];
}

/*
 * Method that update only the active progress view
 */

- (void) updateProgressView:(NSUInteger)num withPercent:(float)percent{
    
    DLog(@"num: %lu", (unsigned long)num);
    DLog(@"percent: %fd", percent);
    
    [_recentViewController updateProgressView:num withPercent:percent];    
}

/*
 *  This method update the _uploadArray info with a new upload with new status
 */
- (void) changeTheUploadsArrayInfoWith:(UploadsOfflineDto *) upload {
    
    for(int i = 0; i < [_uploadArray count] ; i++) {
        ManageUploadRequest *currentUploadRequest = [_uploadArray objectAtIndex:i];
        if (currentUploadRequest.currentUpload.idUploadsOffline == upload.idUploadsOffline) {
            currentUploadRequest.currentUpload = upload;
            [_uploadArray replaceObjectAtIndex:i withObject:currentUploadRequest];
        }
    }
}

/*
 * This method update the badge of the recent tab and
 * update the table of recents view
 */
- (void)updateRecents {
    DLog(@"AppDelegate update Recents and number of error uploads");
    
    __block int errorCount=0;
    __block ManageUploadRequest *currentManageUploadRequest;
    
   // NSArray *uploadsArrayTemp = [NSArray arrayWithArray:_uploadArray];
    
    [_uploadArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        currentManageUploadRequest = obj;
        if (currentManageUploadRequest.currentUpload.kindOfError != notAnError){
            errorCount++;
        }
        
    }];
    
    NSString *errorBadge=nil;
    if (errorCount > 0) {
        errorBadge= [NSString stringWithFormat:@"%d",errorCount ];
    }
    
    DLog(@"ERRORCOUNT: %@", errorBadge);
    
    RecentViewController *currenRecent = [_ocTabBarController.viewControllers objectAtIndex:1];
    
    if (![currenRecent.tabBarItem.badgeValue isEqualToString:errorBadge]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //update badge
            [currenRecent.tabBarItem setBadgeValue:errorBadge];
        });
    }
    
    //update recents
    [_recentViewController updateRecents];
}


/*
 * Remove chunks of temp folder
 *
 */
- (void) removeInboxFolder{
    
    NSFileManager *fileManager= [NSFileManager defaultManager];
    //Create a temp directory in documents folder to store multiple chunks
    NSString *inboxFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Inbox"];
    
    NSError *error;
    [fileManager removeItemAtPath:inboxFolder error:&error];
}

#pragma mark - Manage media player

/*
 * Method that inform if the filePath its playing in media player.
 * @filePath -> file path of the file
 */
- (BOOL)isMediaPlayerRunningWithThisFilePath:(NSString*)filePath{
    
    BOOL output = NO;
    
    if (IS_IPHONE) {
        if (self.avMoviePlayer) {
            if ([self.avMoviePlayer.urlString isEqualToString:filePath]) {
                output = YES;
            }
        }
    }else{
        if (_detailViewController.avMoviePlayer) {
            if ([_detailViewController.avMoviePlayer.urlString isEqualToString:filePath]) {
                output = YES;
            }
        }
    }    
    return output;
}

/*
 * Method that remove media player of the preview screen
 * and free memory
 */
- (void)quitMediaPlayer{
    
    if (IS_IPHONE) {
        if (self.avMoviePlayer) {
            [self.avMoviePlayer.contentOverlayView removeObserver:self forKeyPath:[MediaAVPlayerViewController observerKeyFullScreen]];
            [self.avMoviePlayer.player pause];
            self.avMoviePlayer.player = nil;
            [self.avMoviePlayer.view removeFromSuperview];
            self.avMoviePlayer = nil;
        }
    }
}

#pragma mark - Management of external events wiht Media Player

/*
 * Method that indicate the app that the player can receive external events
 */
- (void)canPlayerReceiveExternalEvents{
    
    // Handle Audio Remote Control events (only available under iOS 4 and later
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(beginReceivingRemoteControlEvents)]){
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
    }
}

/*
 * Method that indicate the player are disable of external events
 */
- (void)disableReceiveExternalEvents{
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(endReceivingRemoteControlEvents)]){
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        [self resignFirstResponder];
    }
    
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


#pragma mark - Multitasking methods

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //For iOS8 we need to change the checking to this method, for show as a first step the pincode screen
    [self closeAlertViewAndViewControllers];
    [self performSelector:@selector(checkIfIsNecesaryShowPassCodeWillResignActive) withObject:nil afterDelay:0.5];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    //In the case that the mediaplayer its running, pause the audio/video file.
   if (self.avMoviePlayer) {
        if (self.avMoviePlayer.isMusic==NO) {
             [self.avMoviePlayer.player pause];
        }
    }
    
    //Launch the notification
    [[NSNotificationCenter defaultCenter] postNotificationName: CloseAlertViewWhenApplicationDidEnterBackground object: nil];
    
    //Close the pop-up of rename in FileViewController
    if(_presentFilesViewController.rename){
        [_presentFilesViewController.rename.renameAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    //Close the pop-up of rename in move in FileViewController
    if (_presentFilesViewController.moveFile) {
        [_presentFilesViewController.moveFile.overWritteOption.renameAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    //Close the pop-up of create a folder in FileViewController
    if (_presentFilesViewController.folderView) {
        [_presentFilesViewController.folderView dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    
    if([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
        DLog(@"Multitasking Supported");
        
        __block UIBackgroundTaskIdentifier background_task;
        background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
            
            //Clean up code. Tell the system that we are done.
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        }];
    } else {
        DLog(@"Multitasking Not Supported");
    }
    
    //Store the version of the app in NSUserDefautls
    [UtilsFileSystem  storeVersionUsed];

}




- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DLog(@"applicationWillEnterForeground");
    
    if (self.activeUser.username==nil) {
        self.activeUser=[ManageUsersDB getActiveUser];
    }
    
    if (self.activeUser.url != nil) {
       [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:self.activeUser.url];
    }
    
    // if we are migrating the url no relaunch pending uploads
    if (![UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:self.activeUser.predefinedUrl]) {

        [self launchUploadsOfflineFromDocumentProvider];
        
        [self relaunchUploadsFailedForced];
        
        //Refresh the tab
        [self performSelector:@selector(updateRecents) withObject:nil afterDelay:0.3];

        //Update the Favorites Files
        [self performSelector:@selector(launchProcessToSyncAllFavorites) withObject:nil afterDelay:5.0];

        //Refresh the list of files from the database
        if (_activeUser && self.presentFilesViewController) {
            [_presentFilesViewController reloadTableFromDataBase];
        }
        
    }

    //Show TouchID dialog if active
    if([ManageAppSettingsDB isTouchID])
        [[ManageTouchID sharedSingleton] showTouchIDAuth];

}



- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    //Set on the user defaults that the app has been killed by user
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setBool:YES forKey:k_app_killed_by_user];
    [standardUserDefaults synchronize];
    
    [self.downloadManager cancelDownloads];
    [[AppDelegate sharedSyncFolderManager] cancelAllDownloads];

    
    //Remove inbox folder if aren't uploads pending
    if (![ManageUploadsDB isFilesInUploadProcess]) {
         [self removeInboxFolder];
    }
}

#pragma mark - Background Fetch methods


//-----------------------------------
/// @name restoreUploadsInProccessFromSystemWithIdentificator
///-----------------------------------

/**
 * Method to recover the upload process from iOS background system
 *
 * @param NSString -> identifier to find the task
 *
 */
- (void) restoreUploadsInProccessFromSystemWithIdentificator: (NSString*)identifier withCompletionHandler:(void (^)())completionHandler {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration];
    
   //Get uploads in the database "waiting for upload" and "uploading" to compare with background uploads
    NSMutableArray *uploadsFromDB = [NSMutableArray new];
    
    [uploadsFromDB addObjectsFromArray:[ManageUploadsDB getUploadsByStatus:waitingForUpload]];
    [uploadsFromDB addObjectsFromArray:[ManageUploadsDB getUploadsByStatus:uploading]];
    
    NSMutableArray *uploadsToRecentsTab = nil;
    uploadsToRecentsTab = [NSMutableArray new];
    
    [urlSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        DLog(@"OC getTaskWithCompletionHandler");
        
        
        NSMutableArray *uploadTaskCopy = [NSMutableArray arrayWithArray:uploadTasks];
        
        for (NSURLSessionUploadTask *upload in uploadTasks) {
            
            DLog(@"OC uplaod task identifier: %lu", (unsigned long)upload.taskIdentifier);
            
            for (UploadsOfflineDto *uploadDB in uploadsFromDB) {
                
                DLog(@"OC upload hash %ld - Database hash %ld", (long)upload.taskIdentifier, (long)uploadDB.taskIdentifier);
                
                if (upload.taskIdentifier == uploadDB.taskIdentifier) {
                    
                    //Create ManageUploadRequest
                    ManageUploadRequest *currentManageUploadRequest = [ManageUploadRequest new];
                    
                    //Insert the specific data to recents view
                    NSDate *uploadedDate = [NSDate dateWithTimeIntervalSince1970:uploadDB.uploadedDate];
                    currentManageUploadRequest.date = uploadedDate;
                    //Set uploadOffline
                    currentManageUploadRequest.currentUpload = uploadDB;
                    currentManageUploadRequest.lenghtOfFile = [UploadUtils makeLengthString:uploadDB.estimateLength];
                    currentManageUploadRequest.userUploading = [ManageUsersDB getUserByIdUser:uploadDB.userId];
                    
                    currentManageUploadRequest.pathOfUpload = [UtilsUrls getPathWithAppNameByDestinyPath:uploadDB.destinyFolder andUser:currentManageUploadRequest.userUploading];
                    
                    currentManageUploadRequest.uploadTask = upload;
                    currentManageUploadRequest.isFromBackground = YES;
                    
                    //Add the object to the array
                    [uploadsToRecentsTab addObject:currentManageUploadRequest];
                    
                    //Remove object from the copy of the uploads
                    [uploadTaskCopy removeObject:upload];
                }
            }
       }
        
        //Remove the uploads not finished and not in the DB
        for (NSURLSessionUploadTask *upload in uploadTaskCopy) {
            [upload cancel];
        }
        
        //This for prevent the duplication of the Uploads in the array
        for (ManageUploadRequest *currentUploadsToRecentsTab in uploadsToRecentsTab) {
            [self addToTheUploadArrayWithoutDuplicatesTheFile:currentUploadsToRecentsTab];
        }
        
        [self updateRecents];
        
        [self getBackgroundTaskFinish];
        
        [self getCallBacksOfUploads];
        
        
        NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
        
        if ([standardUserDefaults boolForKey:k_app_killed_by_user]) {
            [self performSelectorInBackground:@selector(initUploadsOffline) withObject:nil];
        } else {
            [self recoverTheFinishedUploads];
        }
        
        //All the waitingForUpload should be relaunched so we change the state to errorUploading-notAnError
        [self performSelector:@selector(resetWaitingForUploadToErrorUploading) withObject:nil afterDelay:5.0];
    }];
}



//-----------------------------------
/// @name addToTheUploadArrayWithoutDuplicatesTheFile
///-----------------------------------

/**
 * Method to add to the _uploadArray a ManageUploadRequest checking if exist before to prevent duplications
 *
 * @param ManageUploadRequest -> uploadFile
 *
 */
- (void) addToTheUploadArrayWithoutDuplicatesTheFile: (ManageUploadRequest *) uploadFile {
    
    BOOL isExist = NO;
    //Check if the ManageUploadRequest exists on the uploadArray
    for (ManageUploadRequest *currentInUploadArray in [self.uploadArray copy]) {
        if (currentInUploadArray.currentUpload.idUploadsOffline == uploadFile.currentUpload.idUploadsOffline) {
            isExist = YES;
        }
    }
    //If the file doesn't exist add it to the uploadArray
    if (!isExist) {
        [_uploadArray addObject:uploadFile];
    } else {
        [self changeTheUploadsArrayInfoWith:uploadFile.currentUpload];
    }
}

- (void) restoreDownloadsInProccessFromDownloadFolderFromSystemWithIdentificator: (NSString*)identifier withCompletionHandler:(void (^)())completionHandler{
    
    NSURLSessionConfiguration *configuration = nil;
    
    if (k_is_sso_active || !k_is_background_active) {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    } else {
        configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    }
    
    
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration];
    
    [urlSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        //Get downloads in progress from the DataBase
        NSMutableArray *downloadsFromDB = [NSMutableArray new];
        
        [downloadsFromDB addObjectsFromArray:[ManageFilesDB getFilesByDownloadStatus:downloading andUser:self.activeUser]];
        
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            
            for (FileDto *file in downloadsFromDB) {
                
                if (file.taskIdentifier == downloadTask.taskIdentifier) {
                    [[AppDelegate sharedSyncFolderManager] simpleDownloadTheFile:file andTask:downloadTask];
                }
            }
        }
        
        [self getDownloadsFromDownloadFolderTaskFinish];
    }];
}

- (void) restoreDownloadsInProccessFromSystemWithIdentificator: (NSString*)identifier withCompletionHandler:(void (^)())completionHandler{
    
    NSURLSessionConfiguration *configuration = nil;
    
    if (k_is_sso_active || !k_is_background_active) {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    } else {
        configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    }
    
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration];
    
    [urlSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        //Get downloads in progress from the DataBase
        NSMutableArray *downloadsFromDB = [NSMutableArray new];
        
        [downloadsFromDB addObjectsFromArray:[ManageFilesDB getFilesByDownloadStatus:downloading andUser:self.activeUser]];
        
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            
            for (FileDto *file in downloadsFromDB) {
                
                if (file.taskIdentifier == downloadTask.taskIdentifier) {
                    
                    Download *download = [[Download alloc]init];
                    download.downloadTask = downloadTask;
                    download.isFromBackground = YES;
                    download.fileDto = file;
                    
                    //Local folder
                    NSString *localFolder = nil;
                    localFolder = [NSString stringWithFormat:@"%@%ld/%@", [UtilsUrls getOwnCloudFilePath], (long)self.activeUser.idUser, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:self.activeUser]];
                    localFolder = [localFolder stringByRemovingPercentEncoding];
                    
                    download.currentLocalFolder = localFolder;
                    

                    [self.downloadManager addSimpleDownload:download];
                    
                }
            }
        }
        
        [self getCallBacksOfDownloads];
        [self getDownloadsTaskFinish];
       
    }];
}

/*
 *  Method to set the files that are not on the Background but they should be downloading to not download state
 */
- (void) removeDownloadStatusFromFilesLosesOnBackground {
    
    //Get downloads in progress from the DataBase
    NSMutableArray *downloadsFromDB = [NSMutableArray new];
    
    [downloadsFromDB addObjectsFromArray:[ManageFilesDB getFilesByDownloadStatus:downloading andUser:self.activeUser]];
    
    if (downloadsFromDB.count > 0) {
        
        NSMutableArray *tempArray = [NSMutableArray new];
        
        //Files selected manually pending to be download
        for (Download *download in [self.downloadManager getDownloads]) {
            for (FileDto *file in downloadsFromDB) {
                if ([file.filePath isEqualToString:download.fileDto.filePath] && [file.fileName isEqualToString:download.fileDto.fileName]){
                    [tempArray addObject:file];
                }
            }
        }
        
        //Files download folder pending to be download
        
        NSMutableArray *listOfFilesToBeDownloaded = [[NSMutableArray alloc] initWithArray: [AppDelegate sharedSyncFolderManager].listOfFilesToBeDownloaded];
        
        for (DownloadFileSyncFolder *download in listOfFilesToBeDownloaded) {
            for (FileDto *file in downloadsFromDB) {
                if ([file.filePath isEqualToString:download.file.filePath] && [file.fileName isEqualToString:download.file.fileName]){
                    [tempArray addObject:file];
                }
            }
        }
        
        for (FileDto *file in tempArray) {
            [downloadsFromDB removeObjectIdenticalTo:file];
        }
        
        //Put "notdownload" state files are not in the background session
        for (FileDto *file in downloadsFromDB) {
            [ManageFilesDB setFileIsDownloadState:file.idFile andState:notDownload];
        }
        
    }
}

- (void) getDownloadsFromDownloadFolderTaskFinish {
    
    DLog(@"Download in background task finish");
    [[AppDelegate sharedOCCommunicationDownloadFolder] setDownloadTaskComleteBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
        
        NSMutableArray *listOfFilesToBeDownloaded = [[NSMutableArray alloc] initWithArray: [AppDelegate sharedSyncFolderManager].listOfFilesToBeDownloaded];
        
        for (DownloadFileSyncFolder *download in listOfFilesToBeDownloaded) {
            
            if (download.file.taskIdentifier == downloadTask.taskIdentifier /*&& download.file.isFromBackground*/) {
                
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)downloadTask.response;
                DLog(@"HTTP Error: %ld", (long)httpResponse.statusCode);
                
                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                
                    if ([[NSFileManager defaultManager] fileExistsAtPath:download.file.localFolder]) {
                        [download updateDataDownloadSuccess];
                    } else {
                        [download failureDownloadProcess];
                    }
                
                    [self reloadTableFromDataBaseIfFileIsVisibleOnList:download.file];
                    
                } else {
                    //Failure
                    [download failureDownloadProcess];
                    [self reloadTableFromDataBaseIfFileIsVisibleOnList:download.file];
                }
            }
        }
        return nil;
    }];
}


- (void) getDownloadsTaskFinish {
    
    DLog(@"Download in background task finish");
    [[AppDelegate sharedOCCommunication] setDownloadTaskComleteBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
        
        for (Download *download in [self.downloadManager getDownloads]) {
            
            if (download.downloadTask.taskIdentifier == downloadTask.taskIdentifier && download.isFromBackground) {
                
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)downloadTask.response;
                DLog(@"HTTP Error: %ld", (long)httpResponse.statusCode);
                
                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                    
                   // dispatch_async(dispatch_get_main_queue(), ^{
                        [download updateDataDownload];
                        [download setDownloadTaskIdentifierValid:NO];
                  //  });

                    NSString * localPath = [NSString stringWithFormat:@"%@%@", download.currentLocalFolder, [download.fileDto.fileName stringByRemovingPercentEncoding]];
                    NSURL *localPathUrl = [NSURL fileURLWithPath:localPath];
                    return localPathUrl;
                    
                } else {
                    //Failure
                    [download failureDownloadProcess];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if ([(NSObject*)download.delegate respondsToSelector:@selector(downloadFailed:andFile:)] && [(NSObject*)download.delegate respondsToSelector:@selector(errorLogin)]  ) {
                            
                            switch (httpResponse.statusCode) {
                                case kOCErrorServerUnauthorized:
                                    [download.delegate downloadFailed:nil andFile:download.fileDto];
                                    [download.delegate errorLogin];
                                    break;
                                case kOCErrorServerForbidden:
                                    [download.delegate downloadFailed:NSLocalizedString(@"not_establishing_connection", nil) andFile:download.fileDto];
                                    break;
                                case kOCErrorProxyAuth:
                                    [download.delegate downloadFailed:NSLocalizedString(@"not_establishing_connection", nil) andFile:download.fileDto];
                                    break;
                                case kOCErrorServerPathNotFound:
                                    [download.delegate downloadFailed:NSLocalizedString(@"download_file_exist", nil) andFile:download.fileDto];
                                    break;
                                default:
                                    [download.delegate downloadFailed:NSLocalizedString(@"not_possible_connect_to_server", nil) andFile:download.fileDto];
                                    break;
                            }
                        }
                    });
                }
            }
        }
        return nil;
    }];
}

- (void) getCallBacksOfDownloads{
    
    [[AppDelegate sharedOCCommunication] setDownloadTaskDidGetBodyDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        
        for (Download *download in [self.downloadManager getDownloads]) {
            
            if (download.downloadTask.taskIdentifier == downloadTask.taskIdentifier && download.isFromBackground) {
                
                float percent = (((float)totalBytesWritten)/((float)totalBytesExpectedToWrite));
                
                NSString *progressString = nil;
                
                if (totalBytesExpectedToWrite / 1024 == 0) {
                    progressString = [NSString stringWithFormat:@"%ld Bytes / %ld Bytes", (long)totalBytesWritten, (long)totalBytesExpectedToWrite];
                } else {
                    progressString = [NSString stringWithFormat:@"%ld KB / %ld KB", (long)totalBytesWritten/1024, (long)totalBytesExpectedToWrite/1024];
                }
                
                DLog(@"Download progress: %@", progressString);
                
                //We make it on the main thread because we came from a delegate
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (percent > 0) {
                        if ([(NSObject*)download.delegate respondsToSelector:@selector(percentageTransfer:andFileDto:)]) {
                            [download.delegate percentageTransfer:percent andFileDto:download.fileDto];
                        }
                    }
                    if (progressString) {
                        if ([(NSObject*)download.delegate respondsToSelector:@selector(progressString:andFileDto:)]) {
                            [download.delegate progressString:progressString andFileDto:download.fileDto];
                        }
                    }
                });
            }
        }
        DLog(@"Download identifier %lu", (unsigned long)downloadTask.taskIdentifier);
        DLog(@"Task progress: %lld of total: %lld", totalBytesWritten, totalBytesExpectedToWrite);
    }];
}

///-----------------------------------
/// @name Get Background task finished
///-----------------------------------

/**
 * This method set the block Did Complete block that get the success or failure 
 * the network tasks in background
 *
 */
- (void) getBackgroundTaskFinish {
    
    DLog(@"getBackgroundTaskFinish");
    
    [[AppDelegate sharedOCCommunication] setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        
        DLog(@"TASK TERMINATED WITH IDENTIFIER: %lu", (unsigned long)task.taskIdentifier);
        DLog(@"Error code: %ld, and error descripcion: %@", (long)error.code, error.description);
        
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)task.response;
        DLog(@"HTTP Error: %ld", (long)httpResponse.statusCode);
        
        NSMutableArray *uploadsFromDB = [NSMutableArray new];
        
        [uploadsFromDB addObjectsFromArray:[ManageUploadsDB getUploadsByStatus:waitingForUpload]];
        [uploadsFromDB addObjectsFromArray:[ManageUploadsDB getUploadsByStatus:uploading]];
        
        
        DLog(@"uploadsFromDB: %lu", (unsigned long)[uploadsFromDB count]);
        
        for (UploadsOfflineDto *uploadOffline in uploadsFromDB) {
            
            __block ManageUploadRequest *uploadRequest = nil;
            
            //Get the ManageUploadRequest of the UploadOffline
            for (ManageUploadRequest *tempRequest in [self.uploadArray copy]) {
                if (tempRequest.currentUpload.idUploadsOffline == uploadOffline.idUploadsOffline) {
                    uploadRequest = tempRequest;
                    break;
                }
            }
            
           // DLog(@"CHECK UPLOADRESQUEST TASK: %d", uploadRqst.taskIdentifier);
            if (uploadOffline.taskIdentifier == task.taskIdentifier && uploadRequest.isFromBackground == YES) {
                
                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                    //Success
                    uploadOffline.status = uploaded;
                    [ManageUploadsDB setStatus:uploaded andKindOfError:notAnError byUploadOffline:uploadOffline];
                    
                    //Update uploaded date
                    uploadOffline.uploadedDate = [[NSDate date] timeIntervalSince1970];
                    [ManageUploadsDB setDatebyUploadOffline:uploadOffline];
                    
                    FileDto *current = [UploadUtils getFileDtoByUploadOffline:uploadOffline];
                    
                    if (current && current.isDownload == overwriting) {
                        [ManageFilesDB setFileIsDownloadState:current.idFile andState:downloaded];
                    
                        ManageUploadRequest *uploadRequest = [ManageUploadRequest new];
                        [uploadRequest updateTheEtagOfTheFile:current];
                    }
                    
                    [self changeTheUploadsArrayInfoWith:uploadOffline];
                    
                } else {
                    //Failure
                    DLog(@"Error code: %ld, and error descripcion: %@", (long)error.code, error.description);
                    
                    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    
                    DLog(@"Error: %@", error);
                    DLog(@"error.code: %ld", (long)error.code);
                    
                    if ([error code] != NSURLErrorCancelled) {
                        
                        NSInteger errorToCheck = 0;
                        
                        if (httpResponse.statusCode > 0) {
                            errorToCheck = httpResponse.statusCode;
                        } else {
                            errorToCheck = error.code;
                        }
                        
                        DLog(@"errorToCheck:%ld", (long)errorToCheck);
                        DLog(@"error.code:%ld", (long)error.code);
                        DLog(@"httpResponse.statusCode:%ld", (long)httpResponse.statusCode);
                        
                        //We set the kindOfError in case that we have a credential or if the file where we want upload not exist
                        switch (errorToCheck) {
                            case kOCErrorServerUnauthorized:
                                uploadOffline.status = errorUploading;
                                uploadOffline.kindOfError = errorCredentials;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:uploadOffline.kindOfError byUploadOffline:uploadOffline];
                                [appDelegate cancelTheCurrentUploadsWithTheSameUserId:uploadOffline.userId];
                                break;
                            case kOCErrorServerForbidden:
                                uploadOffline.status = errorUploading;
                                if (error.code == OCErrorForbiddenWithSpecificMessage) {
                                    uploadOffline.kindOfError = errorFirewallRuleNotAllowUpload;
                                } else {
                                    uploadOffline.kindOfError = errorNotPermission;
                                }
                                break;
                            case kOCErrorProxyAuth:
                                uploadOffline.status = errorUploading;
                                uploadOffline.kindOfError = errorCredentials;
                                [appDelegate cancelTheCurrentUploadsWithTheSameUserId:uploadOffline.userId];
                                break;
                            case kOCErrorServerPathNotFound:
                                uploadOffline.status = errorUploading;
                                uploadOffline.kindOfError = errorDestinyNotExist;
                                break;
                            case kOCErrorServerInternalError:
                                uploadOffline.status = errorUploading;
                                uploadOffline.kindOfError = errorUploadInBackground;
                                break;
                            case kCFURLErrorNotConnectedToInternet:
                                uploadOffline.status = errorUploading;
                                uploadOffline.kindOfError = notAnError;
                                break;
                            case kCFURLErrorCannotConnectToHost:
                                uploadOffline.status = pendingToBeCheck;
                                uploadOffline.kindOfError = notAnError;
                                break;
                            default:
                                uploadOffline.status = errorUploading;
                                uploadOffline.kindOfError = notAnError;
                                break;
                        }
                        [ManageUploadsDB setStatus:uploadOffline.status andKindOfError:uploadOffline.kindOfError byUploadOffline:uploadOffline];
                        [self changeTheUploadsArrayInfoWith:uploadOffline];
                        
                    } else {
                        DLog(@"Upload canceled");
                    }
                }
            }
        }
      [self updateRecents];
    }];
}

//-----------------------------------
/// @name getCallBacksOfUploads
///-----------------------------------

/**
 * Method to obtain the percent of the current upload
 *
 */
- (void)getCallBacksOfUploads {
    
    DLog(@"getCallBacksOfUploads");

    [[AppDelegate sharedOCCommunication] setTaskDidSendBodyDataBlock:^(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        
        DLog(@"Task identifier: %lu", (unsigned long)task.taskIdentifier);
        
        DLog(@"Task progress: %lld  or %lld - of total: %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
        
        DLog(@"uploadArray: %lu", (unsigned long)_uploadArray.count);
        
        BOOL isTheTaskOnTheDB = NO;
        
        for (ManageUploadRequest *uploadRequest in [self.uploadArray copy]) {

            if (uploadRequest.uploadTask.taskIdentifier == task.taskIdentifier) {
                
                //DLog(@"Upload Task Identifier: %d", uploadRequest.uploadTask.taskIdentifier);
                
                isTheTaskOnTheDB = YES;
                
                if (uploadRequest.isFromBackground) {
                    if (uploadRequest.currentUpload.status == waitingForUpload && !uploadRequest.isUploadBegan) {
                        uploadRequest.isUploadBegan = YES;
                        [ManageUploadsDB setStatus:uploading andKindOfError:notAnError byUploadOffline:uploadRequest.currentUpload];
                        uploadRequest.currentUpload.status=uploading;
                        [self updateRecents];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        DLog(@"Task progress: %lld  or %lld - of total: %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
                        float percent = (((float)totalBytesSent)/((float)totalBytesExpectedToSend));
                        DLog(@"Percent is: %f", percent);
                        [uploadRequest updateProgressWithPercent:percent];
                    });
                }
                
              break;
            }
            
        }
        
    
        if (!isTheTaskOnTheDB) {
            [task cancel];
        }
    }];
}


-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  [self.downloadManager changeBehaviourForBackgroundFetch:YES];
    
    if (([self.downloadManager getDownloads].count > 0) ||
        ([AppDelegate sharedSyncFolderManager].listOfFilesToBeDownloaded.count > 0)) {
        completionHandler(UIBackgroundFetchResultNewData);
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}


/*
 *  Method called by the system when all the background task has end
 */
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSLog(@"OC handle Events for Background URL Session");
    
    DLog(@"_uploadArray: %@", @(_uploadArray.count));
    
    [self updateStateAndRestoreUploadsAndDownloads];
   
    //We need some time 30 secs max to call the completion handler
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
                       
                       if ([self.downloadManager getDownloads].count > 0) {
                           completionHandler(UIBackgroundFetchResultNewData);
                       } else {
                           completionHandler(UIBackgroundFetchResultNoData);
                       }
                    
                   });
}


#pragma mark - Pass Code

- (void)checkIfIsNecesaryShowPassCode {
    if ([ManageAppSettingsDB isPasscode] || k_is_passcode_forced) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            KKPasscodeViewController* vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
            vc.delegate = self;
            
            OCPortraitNavigationViewController *oc = [[OCPortraitNavigationViewController alloc]initWithRootViewController:vc];
            
            if([ManageAppSettingsDB isPasscode]) {
                vc.mode = KKPasscodeModeEnter;
            } else {
                vc.mode = KKPasscodeModeSet;
            }

            self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            
            UIViewController *rootController = [[UIViewController alloc]init];
            self.window.rootViewController = rootController;
            [self.window makeKeyAndVisible];
            
            if (IS_IPHONE) {
                
                [rootController presentViewController:oc animated:YES completion:nil];
                
            } else {
                oc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                oc.modalPresentationStyle = UIModalPresentationFormSheet;
                [rootController presentViewController:oc animated:NO completion:nil];
            }
        });
    } else {        
        [self initAppWithEtagRequest:YES];
    }
  
}

- (void)checkIfIsNecesaryShowPassCodeWillResignActive {
    
    if ([ManageAppSettingsDB isPasscode] || k_is_passcode_forced) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            KKPasscodeViewController* vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
            vc.delegate = self;
            
            OCPortraitNavigationViewController *oc = [[OCPortraitNavigationViewController alloc]initWithRootViewController:vc];
            
            if([ManageAppSettingsDB isPasscode]) {
                vc.mode = KKPasscodeModeEnter;
            } else {
                vc.mode = KKPasscodeModeSet;
            }

            if (IS_IPHONE) {
                
                UIViewController *topView = [self topViewController];
                
                if (topView) {
                    if (![topView isKindOfClass:[KKPasscodeViewController class]]) {
                        _currentViewVisible = topView;
                   }
                }
                [_currentViewVisible presentViewController:oc animated:NO completion:nil];
                
                
            } else {
                //is ipad
                [_splitViewController dismissViewControllerAnimated:NO completion:nil];
                
                // oc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                oc.modalPresentationStyle = UIModalPresentationFormSheet;
                
                [_splitViewController presentViewController:oc animated:NO completion:^{
                    DLog(@"present complete");
                }];
            }
        });
    }
}


///-----------------------------------
/// @name Close alertViews and ViewControllers
///-----------------------------------

/**
 * This method close the alertViews and the ViewController when the pincode is on
 * and the app goes to background
 */
- (void) closeAlertViewAndViewControllers {
    
    if (self.presentFilesViewController){
        //Close the openWith option in FileViewController
        if (self.presentFilesViewController.openWith) {
            [self.presentFilesViewController.openWith.activityView dismissViewControllerAnimated:NO completion:nil];
        }
        //Close the delete option in FilesViewController
        if (self.presentFilesViewController.mDeleteFile.popupQuery) {
            [self.presentFilesViewController.mDeleteFile.popupQuery dismissWithClickedButtonIndex:0 animated:NO];
        }
        
        //Close the more view controller on the list of FilesViewController
        if (self.presentFilesViewController.moreActionSheet) {
            [self.presentFilesViewController.moreActionSheet dismissWithClickedButtonIndex:self.presentFilesViewController.moreActionSheet.cancelButtonIndex animated:NO];
        }
        
        //Close the plus view controller on the list of FilesViewController
        if (self.presentFilesViewController.plusActionSheet) {
            [self.presentFilesViewController.plusActionSheet dismissWithClickedButtonIndex:self.presentFilesViewController.plusActionSheet.cancelButtonIndex animated:NO];
        }
        
        //Close the sort view controller on the list of FilesViewController
        if (self.presentFilesViewController.sortingActionSheet) {
            [self.presentFilesViewController.sortingActionSheet dismissWithClickedButtonIndex:self.presentFilesViewController.sortingActionSheet.cancelButtonIndex animated:NO];
        }
        
        //Create folder
        if (self.presentFilesViewController.folderView) {
            [self.presentFilesViewController.folderView dismissWithClickedButtonIndex:self.presentFilesViewController.folderView.cancelButtonIndex animated:NO];
        }
        
        //Rename folder
        if (self.presentFilesViewController.rename.renameAlertView) {
            [self.presentFilesViewController.rename.renameAlertView dismissWithClickedButtonIndex:self.presentFilesViewController.rename.renameAlertView.cancelButtonIndex animated:NO];
        }
        
    }
    
    if (self.settingsViewController){
        //Close the pop-up of twitter and facebook in SettingViewController
        if (self.settingsViewController.popupQuery) {
            [self.settingsViewController.popupQuery dismissWithClickedButtonIndex:self.settingsViewController.popupQuery.cancelButtonIndex animated:NO];
        }
        if (self.settingsViewController.twitter) {
            [self.settingsViewController.twitter dismissViewControllerAnimated:NO completion:nil];
        }
        if (self.settingsViewController.facebook) {
            [self.settingsViewController.facebook dismissViewControllerAnimated:NO completion:nil];
        }
        //Close the view of mail in SettingViewController
        if (self.settingsViewController.mailer) {
            [self.settingsViewController.mailer dismissViewControllerAnimated:NO completion:nil];
        }
        //Close the pincode view controller in SettingViewController
        if (self.settingsViewController.vc) {
            [self.settingsViewController.vc dismissViewControllerAnimated:NO completion:nil];
        }
        //Close the pincode view controller in SettingViewController
        if (self.settingsViewController.vc) {
            [self.settingsViewController.vc dismissViewControllerAnimated:NO completion:nil];
        }
        //Close user actionsheet view controller in SettingViewController
        if (self.settingsViewController.menuAccountActionSheet) {
            [self.settingsViewController.menuAccountActionSheet dismissWithClickedButtonIndex:self.settingsViewController.menuAccountActionSheet.cancelButtonIndex animated:NO];
        }
    }
}

- (UIViewController *)topViewController{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
        
        /*
         UIViewController *lastViewController;
         
         for (id current in [navigationController viewControllers]) {
         
         if (![current isKindOfClass:[UIAlertController class]]) {
         lastViewController = current;
         }
         
         }
         */
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

//- (UIViewController*)topViewController {
//    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
//}
//
//- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
//    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
//        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
//        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
//    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
//        UINavigationController* navigationController = (UINavigationController*)rootViewController;
//        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
//    } else if (rootViewController.presentedViewController) {
//        UIViewController* presentedViewController = rootViewController.presentedViewController;
//        return [self topViewControllerWithRootViewController:presentedViewController];
//    } else {
//        return rootViewController;
//    }
//}


#pragma mark - Pass Code Delegate Methods

- (void)didPasscodeEnteredCorrectly:(KKPasscodeViewController*)viewController{
    DLog(@"Did pass code entered correctly");
    
    [self initViewsAfterDismissPasscode];
}

- (void)didPasscodeEnteredIncorrectly:(KKPasscodeViewController*)viewController{
    DLog(@"Did pass code entered incorrectly");
}

- (void)didSettingsChanged:(KKPasscodeViewController *)viewController {
    DLog(@"Did pass code entered correctly after enforce passcode set");
    [self initViewsAfterDismissPasscode];
}

- (void)initViewsAfterDismissPasscode {
    
    if (_isFileFromOtherAppWaitting==YES) {
        if (!_filesViewController) {
            [self initAppWithEtagRequest:YES];
            
        } else {
            [self performSelector:@selector(presentUploadFromOtherApp) withObject:nil afterDelay:0.5];
        }
    } else {
        //If it's first open
        if (!_filesViewController) {
            [self initAppWithEtagRequest:YES];
            
        } else {
            
            if(_presentFilesViewController.rename.renameAlertView){
                [_presentFilesViewController.rename.renameAlertView dismissWithClickedButtonIndex:0 animated:NO];
            }
            if (_presentFilesViewController.moreActionSheet){
                [_presentFilesViewController.moreActionSheet dismissWithClickedButtonIndex:k_max_number_options_more_menu animated:NO];
            }
            if (_presentFilesViewController.plusActionSheet){
                [_presentFilesViewController.plusActionSheet dismissWithClickedButtonIndex:k_max_number_options_plus_menu animated:NO];
            }
            if (_presentFilesViewController.sortingActionSheet) {
                [_presentFilesViewController.sortingActionSheet dismissWithClickedButtonIndex:k_max_number_options_sort_menu animated:NO];
            }
            
            if (_splitViewController) {
                [_splitViewController dismissViewControllerAnimated:NO completion:nil];
            } else {
                [_ocTabBarController dismissViewControllerAnimated:NO completion:nil];
            }
        }
    }
}



#pragma mark - Items to upload from other apps

- (void)itemToUploadFromOtherAppWithName:(NSString*)name andPathName:(NSString*)pathName andRemoteFolder:(NSString*)remFolder andIsNotNeedCheck:(BOOL) isNotNecessaryCheckIfExist{
    
    if(_prepareFiles == nil) {
        _prepareFiles = [[PrepareFilesToUpload alloc] init];
        _prepareFiles.listOfFilesToUpload = [[NSMutableArray alloc] init];
        _prepareFiles.listOfAssetsToUpload = [[NSMutableArray alloc] init];
        _prepareFiles.arrayOfRemoteurl = [[NSMutableArray alloc] init];
        _prepareFiles.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
        _prepareFiles.delegate = self;
    }
    
    uploadTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // If you’re worried about exceeding 10 minutes, handle it here
    }];
    
    name = [name encodeString:NSUTF8StringEncoding];
    long long fileLength = [[[[NSFileManager defaultManager] attributesOfItemAtPath:pathName error:nil] valueForKey:NSFileSize] unsignedLongLongValue];
    
    UploadsOfflineDto *currentUpload = [[UploadsOfflineDto alloc] init];
    currentUpload.originPath = pathName;
    currentUpload.destinyFolder = remFolder;
    currentUpload.uploadFileName = name;
    currentUpload.kindOfError = notAnError;
    
    currentUpload.estimateLength = (long)fileLength;
    currentUpload.userId = _activeUser.idUser;
    currentUpload.isLastUploadFileOfThisArray = YES;
    currentUpload.status = waitingAddToUploadList;
    currentUpload.chunksLength = k_lenght_chunk;
    currentUpload.isNotNecessaryCheckIfExist = isNotNecessaryCheckIfExist;
    currentUpload.isInternalUpload = NO;
    currentUpload.taskIdentifier = 0;
    
    
    [ManageUploadsDB insertUpload:currentUpload];
    currentUpload = [ManageUploadsDB getNextUploadOfflineFileToUpload];
    
    [_prepareFiles sendFileToUploadByUploadOfflineDto:currentUpload];
}


#pragma mark - PrepareFilesToUploadDelegate methods

/*
 * Check if data base is ok an then refresh actual file list if not
 * check again after one second.
 */

- (void)checkAndRefreshFiles{
    DLog(@"AppDelegate - checkAndRefreshFiles");
    
    [_presentFilesViewController initLoading];
    [_presentFilesViewController refreshTableFromWebDav];
}

- (void)refreshAfterUploadAllFiles:(NSString *) currentRemoteFolder {
    DLog(@"refreshAfterUploadAllFiles");
    
    NSString *remoteUrlWithoutDomain = [UtilsUrls getHttpAndDomainByURL:currentRemoteFolder];
    remoteUrlWithoutDomain = [currentRemoteFolder substringFromIndex:remoteUrlWithoutDomain.length];
    
    NSString *currentFolderWithoutDomain = [UtilsUrls getHttpAndDomainByURL:_presentFilesViewController.currentRemoteFolder];
    currentFolderWithoutDomain = [_presentFilesViewController.currentRemoteFolder substringFromIndex:currentFolderWithoutDomain.length];
    
    //Only if is selected the first item: FileList.
    if (_ocTabBarController.selectedIndex == 0 && !_isUploadViewVisible ) {
        
        if ([remoteUrlWithoutDomain isEqualToString:currentFolderWithoutDomain]) {
            [self checkAndRefreshFiles];
        }
    }
    
    _prepareFiles=nil;
    
    //End of the background task
    if (uploadTask) {
        [[UIApplication sharedApplication] endBackgroundTask:uploadTask];
    }
}

- (void) reloadTableFromDataBase {
    [_presentFilesViewController initLoading];
    [_presentFilesViewController reloadTableFromDataBase];
}

- (void)errorWhileUpload{
    
    //End of the background task
    if (uploadTask) {
        [[UIApplication sharedApplication] endBackgroundTask:uploadTask];
    }
    
}

- (void) errorLogin {

    [self performSelector:@selector(delayLoadEditAccountAfterErroLogin) withObject:nil afterDelay:0.1];
}

-(void) delayLoadEditAccountAfterErroLogin {
    
    EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:_activeUser andLoginMode:LoginModeExpire];
    
    if (IS_IPHONE)
    {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        [_ocTabBarController presentViewController:navController animated:YES completion:nil];
    } else {
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.splitViewController presentViewController:navController animated:YES completion:nil];
    }
}


#pragma markt - LocalPath by version

//We move the folders if we have the old version when we save the data on Documents to the new folder
-(void) moveIfIsNecessaryFilesAfterUpdateAppFromTheOldFolderArchitecture {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSFileManager *manager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *fileEnumerator = [manager enumeratorAtPath:documentsPath];
    
    BOOL isNecessaryMoveFolders = NO;
    
    for (NSString *filename in fileEnumerator) {
        
        if ([filename isEqualToString:@"DB.sqlite"]) {
            isNecessaryMoveFolders = YES;
        }
    }
    
    if (isNecessaryMoveFolders) {
        
        fileEnumerator = [manager enumeratorAtPath:documentsPath];
        
        for (NSString *filename in fileEnumerator) {
            
            NSError*    theError = nil;
            [[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"%@/%@",documentsPath,filename] toPath:[NSString stringWithFormat:@"%@%@",[UtilsUrls getOwnCloudFilePath],filename] error:&theError];
        
            if(theError) {
                DLog(@"Error: %@", theError);
            }
        }
    }
}

/*
 * This methods is called after that this class receive the notification that the user
 * has resolved the credentials error
 * In this method we changed the credentials in currents uploads
 * for a specific user
 *
 */
- (void) cancelTheCurrentUploadsWithTheSameUserId:(NSInteger)idUser{
    
    __block ManageUploadRequest *currentManageUploadRequest = nil;
    
    //__block BOOL shouldBeContinue=NO;
    
    DLog(@"id user: %ld", (long)idUser);
    
    NSArray *currentUploadsTemp = [NSArray arrayWithArray:_uploadArray];
    
    [currentUploadsTemp enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DLog(@"looping the item :%ld of the global array", (long)idx);
        
        currentManageUploadRequest = obj;
        DLog(@"the status of the upload is: %ld", (long)currentManageUploadRequest.currentUpload.status);
        if (currentManageUploadRequest.currentUpload.status == waitingForUpload ||
            currentManageUploadRequest.currentUpload.status == uploading) {
            DLog(@"this upload is waiting for upload");
            if (currentManageUploadRequest.currentUpload.userId == idUser) {
                //change the credentiasl
                [currentManageUploadRequest changeTheStatusToFailForCredentials];
                DLog(@"%@ its change to fail", currentManageUploadRequest.currentUpload.originPath);
            }
        }
    }];
    
    
    [self updateRecents];
}


#pragma mark - Clean the upload folder

- (void) cleanUploadFolder {
    
    NSError *error;
    
    if ([[ManageUploadsDB getUploadsByStatus:errorUploading] count] == 0 &&
        [[ManageUploadsDB getUploadsByStatus:waitingForUpload] count] == 0 &&
        [[ManageUploadsDB getUploadsByStatus:uploading] count] == 0 &&
        [[ManageUploadsDB getUploadsByStatus:pendingToBeCheck] count] == 0 &&
        _uploadFromOtherAppViewController == nil) {
        //If we do not have anything waiting to be upload we clean the folder
        [[NSFileManager defaultManager] removeItemAtPath:[UtilsUrls getTempFolderForUploadFiles] error:&error];
    }
}


- (void) updateStateAndRestoreUploadsAndDownloads {
    
    [self updateTheDownloadState:updating to:downloaded];
    
    DLog(@"updateStateAndRestoreUploadsAndDownloads");
    
    if (k_is_sso_active || !k_is_background_active) {
        [self performSelectorInBackground:@selector(initUploadsOffline) withObject:nil];
        [self updateTheDownloadState:downloading to:notDownload];
    } else {
        [AppDelegate sharedOCCommunicationDownloadFolder];
        [self restoreUploadsInProccessFromSystemWithIdentificator:k_session_name withCompletionHandler:nil];
        [self restoreDownloadsInProccessFromSystemWithIdentificator:k_download_session_name withCompletionHandler:nil];
        [self restoreDownloadsInProccessFromDownloadFolderFromSystemWithIdentificator:k_download_folder_session_name withCompletionHandler:nil];
        
        //We use a delay to have time to restoreDownloadsInProccess methods that works in an async way
        [self performSelector:@selector(removeDownloadStatusFromFilesLosesOnBackground) withObject:nil afterDelay:3.0];
    }
    
    [self addErrorUploadsToRecentsTab];
    
}

/*
 *  This method set all the files that are waitingForUpload to errorUploading-notAnError to be relaunched
 */
- (void) resetWaitingForUploadToErrorUploading {
    
    NSArray *waitingArray = [ManageUploadsDB getUploadsByStatus:waitingForUpload];
    
    for (UploadsOfflineDto *current in waitingArray) {
        [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:current];
    }
}

//-----------------------------------
/// @name initUploadsOffline
///-----------------------------------

/**
 * Method to relaunch the UploadsOffline after came from background or when we killed the app
 *
 */
- (void) initUploadsOffline {
    
    [ManageUploadsDB updateAllUploadsWithNotNecessaryCheck];
    
    NSMutableArray *allUploads = [ManageUploadsDB getUploads];
    NSMutableArray *allUploadsToBeModified = [NSMutableArray arrayWithArray:allUploads];
    
    //We save on allUploadsToBeModified the UploadsOfflineDto that are not on the _uploadArray (the files that are uploading now). On iOS6 _uploadArray should be empty
    for (ManageUploadRequest *currentUploadRequest in _uploadArray) {
        for (UploadsOfflineDto *currentUploadOffline in allUploads) {
            if (currentUploadOffline.idUploadsOffline == currentUploadRequest.currentUpload.idUploadsOffline) {
                
                UploadsOfflineDto *uploadToBeRemoved = nil;
                
                for (UploadsOfflineDto *current in allUploadsToBeModified) {
                    if (current.idUploadsOffline == currentUploadOffline.idUploadsOffline) {
                        uploadToBeRemoved = current;
                    }
                }
                if (uploadToBeRemoved) {
                    [allUploadsToBeModified removeObjectIdenticalTo:uploadToBeRemoved];
                }
            }
        }
    }
    
    
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([standardUserDefaults boolForKey:k_app_killed_by_user] || k_is_sso_active) {
        //We set all the UploadsOfflineDto that are not uploading but should as ready to be uploaded
        [ManageUploadsDB updateNotFinalizeUploadsOfflineBy:allUploadsToBeModified];
    } else {
        [self checkTheUploadFilesOnTheServer: allUploadsToBeModified];
    }
    
    //We clean the tmp folder and the list
    [self cleanUploadFolder];
    [ManageUploadsDB saveInUploadsOfflineTableTheFirst:k_number_uploads_shown];
    
    
    //Add finished uploads to Array
    [self addFinishedUploadsOfflineDataToUploadsArray];
    
    [standardUserDefaults setBool:NO forKey:k_app_killed_by_user];
    [standardUserDefaults synchronize];
    
    //Refresh the tab
    [self performSelector:@selector(updateRecents) withObject:nil afterDelay:0.3];
}

//-----------------------------------
/// @name recoverTheFinishedUploads
///-----------------------------------

/**
 * Method to relaunch the UploadsOffline after came from background or when we killed the app
 *
 */
- (void) recoverTheFinishedUploads {
    
    //Add finished uploads to Array
    [self addFinishedUploadsOfflineDataToUploadsArray];
    
    NSMutableArray *allUploads = [ManageUploadsDB getUploads];
    [self checkTheUploadFilesOnTheServerWithoutFailure: allUploads];
    
    //Refresh the tab
    [self performSelector:@selector(updateRecents) withObject:nil afterDelay:0.3];
}

//-----------------------------------
/// @name checkTheUploadFilesOnTheServer
///-----------------------------------

/**
 * Method called to check if a file was uploaded on the server
 *
 * @param NSArray -> uploadsBackground
 *
 */
- (void) checkTheUploadFilesOnTheServer: (NSArray *) uploadsBackground {
    
    for (UploadsOfflineDto *currentUploadBackground in uploadsBackground) {
        if ((currentUploadBackground.status != uploaded) && (currentUploadBackground.status != errorUploading)) {
            NSString * path = [NSString stringWithFormat:@"%@%@", [currentUploadBackground.destinyFolder stringByRemovingPercentEncoding ], currentUploadBackground.uploadFileName];
            
            [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
                if (items != nil && [items count] > 0) {
                    FileDto *currentFile = [items objectAtIndex:0];
                    [self theFileWasUploadedByCurrentUploadInBackground:currentUploadBackground andCurrentFile:currentFile];
                }
                
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                //Check the error for to know if there is a server connection error
                if (error.code == kCFURLErrorCannotConnectToHost) {
                    //The connection of the server is down. Set the status of the file to: "Pending to be check"
                    DLog(@"The server is down");
                    [ManageUploadsDB setStatus:pendingToBeCheck andKindOfError:notAnError byUploadOffline:currentUploadBackground];
                    [self addPendingToCheckUploadsToRecentsTab];
                } else {
                    //Set the file status as a background error
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:currentUploadBackground];
                    //Update the currentUploadBackground with DB
                    UploadsOfflineDto *fileForUpload = [ManageUploadsDB getUploadOfflineById:(int)currentUploadBackground.idUploadsOffline];
                    [self createAManageRequestUploadWithTheUploadOffline:fileForUpload];
                    DLog(@"The file is not on server");
                    [self relaunchUploadsFailed:YES];
                
                }
            }];
        }
    }
}

//-----------------------------------
/// @name checkTheUploadFilesOnTheServerWithoutFailure
///-----------------------------------

/**
 * Method called to check if a file was uploaded on the server and if is not do nothing
 *
 * @param NSArray -> uploadsBackground
 *
 */
- (void) checkTheUploadFilesOnTheServerWithoutFailure: (NSArray *) uploadsBackground {
    
    for (UploadsOfflineDto *currentUploadBackground in uploadsBackground) {
        if ((currentUploadBackground.status != uploaded) && (currentUploadBackground.status != errorUploading)) {
            NSString * path = [NSString stringWithFormat:@"%@%@", [currentUploadBackground.destinyFolder stringByRemovingPercentEncoding ], currentUploadBackground.uploadFileName];
            
            [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
                if (items != nil && [items count] > 0) {
                    FileDto *currentFile = [items objectAtIndex:0];
                    [self theFileWasUploadedByCurrentUploadInBackground:currentUploadBackground andCurrentFile:currentFile];
                }
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
//                //Do nothing
//                [ManageUploadsDB setStatus:pendingToBeCheck andKindOfError:notAnError byUploadOffline:currentUploadBackground];
//                [self addPendingToCheckUploadsToRecentsTab];
//                DLog(@"Pending to be check: %d", currentUploadBackground.status);
            }];
        }
    }
}

//-----------------------------------
/// @name theFileWasUploadedByCurrentUploadInBackground
///-----------------------------------

/**
 * Method to mark a file as uploaded after be uploaded in background without success
 *
 * @param UploadsOfflineDto -> currentUploadBackground
 * @param FileDto -> currentFile
 *
 */
- (void) theFileWasUploadedByCurrentUploadInBackground:(UploadsOfflineDto *) currentUploadBackground andCurrentFile:(FileDto *) currentFile {
    
    DLog(@"file date: %ld", currentFile.date);
    
    currentUploadBackground.uploadedDate = currentFile.date;
    [ManageUploadsDB setDatebyUploadOffline:currentUploadBackground];
    //Set the file status as uploaded
    [ManageUploadsDB setStatus:uploaded andKindOfError:notAnError byUploadOffline:currentUploadBackground];
    //Update the currentUploadBackground with DB
    UploadsOfflineDto *fileForUpload = [ManageUploadsDB getUploadOfflineById:(int)currentUploadBackground.idUploadsOffline];
    [self createAManageRequestUploadWithTheUploadOffline:fileForUpload];
    DLog(@"The file is on server");
    
    currentFile = [ManageFilesDB getFileDtoByFileName:currentUploadBackground.uploadFileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:currentFile.filePath andUser:self.activeUser] andUser:self.activeUser];
    
    if (currentFile.isDownload == overwriting) {
        [ManageFilesDB setFileIsDownloadState:currentFile.idFile andState:downloaded];
        
        ManageUploadRequest *uploadRequest = [ManageUploadRequest new];
        [uploadRequest updateTheEtagOfTheFile:currentFile];
    }
}

//-----------------------------------
/// @name createAManageRequestUploadWithTheUploadOffline
///-----------------------------------

/**
 * Method to create a ManageUploadRequest from a UploadsOfflineDto
 *
 * @param UploadsOfflineDto -> currentUploadBackground
 *
 */
- (void) createAManageRequestUploadWithTheUploadOffline: (UploadsOfflineDto*) currentUploadBackground {

    //Create ManageUploadRequest
    ManageUploadRequest *currentManageUploadRequest = [ManageUploadRequest new];
    
    //Insert the specific data to recents view
    NSDate *uploadedDate = [NSDate dateWithTimeIntervalSince1970:currentUploadBackground.uploadedDate];
    currentManageUploadRequest.date = uploadedDate;
    currentManageUploadRequest.currentUpload.uploadedDate = uploadedDate.timeIntervalSince1970;
    //Set uploadOffline
    currentManageUploadRequest.currentUpload = currentUploadBackground;
    currentManageUploadRequest.lenghtOfFile = [UploadUtils makeLengthString:currentUploadBackground.estimateLength];
    currentManageUploadRequest.userUploading = [ManageUsersDB getUserByIdUser:currentUploadBackground.userId];
    
    currentManageUploadRequest.pathOfUpload = [UtilsUrls getPathWithAppNameByDestinyPath:currentUploadBackground.destinyFolder andUser:currentManageUploadRequest.userUploading];
    
    currentManageUploadRequest.isFromBackground = YES;
    
    //This for prevent the duplication of the Uploads in the array
    [self addToTheUploadArrayWithoutDuplicatesTheFile:currentManageUploadRequest];
    
    [self updateRecents];
}

///-----------------------------------
/// @name Update the download state
///-----------------------------------

/**
 * This method updates the download state of a file
 *
 * @param int -> The initial state
 * @param int -> The final state
 */
- (void) updateTheDownloadState: (int) previousState to:(int) newState {
    //Obtain all the file with previous status
    NSMutableArray *listOfFiles = [ManageFilesDB getFilesByDownloadStatus:previousState andUser:self.activeUser];
    DLog(@"There are: %lu in the list of files", (unsigned long)listOfFiles.count);
    
    //First, check if there are
    if (listOfFiles.count > 0) {
        for (FileDto *file in listOfFiles) {
            //Update the download status of the files
            file.isDownload = newState;
            [ManageFilesDB setFileIsDownloadState:file.idFile andState:newState];
        }
    }
}

#pragma mark - Recent Tab and methods with uploads

/*
 * This method add the finished files data of the uploads_offline table to uploadsArray
 */
- (void) addFinishedUploadsOfflineDataToUploadsArray{
    
    //1.- An array of Uploads
    NSArray *uploadsFromDB = nil;
    uploadsFromDB = [ManageUploadsDB getUploadsByStatus:uploaded andByKindOfError:notAnError];
    
    //for in
    for(UploadsOfflineDto *current in uploadsFromDB) {
        
        //Create the object
        ManageUploadRequest *currentManageUploadRequest = [ManageUploadRequest new];
        
        //Insert the specific data to recents view
        NSDate *uploadedDate = [NSDate dateWithTimeIntervalSince1970:current.uploadedDate];
        currentManageUploadRequest.date = uploadedDate;
        //Set uploadOffline
        currentManageUploadRequest.currentUpload = current;
        currentManageUploadRequest.lenghtOfFile = [UploadUtils makeLengthString:current.estimateLength];
        currentManageUploadRequest.userUploading = [ManageUsersDB getUserByIdUser:current.userId];
        
        currentManageUploadRequest.pathOfUpload = [UtilsUrls getPathWithAppNameByDestinyPath:current.destinyFolder andUser:currentManageUploadRequest.userUploading];
        
        //Add the object to the uploadArray without duplicates
        [self addToTheUploadArrayWithoutDuplicatesTheFile:currentManageUploadRequest];
    }
}


/*
 * Method to add to the _uploadArray all the files that fails before
 * This method has a timeout
 *@isForced -> If YES the timeout is 0 secs
 */
- (void) addErrorUploadsToRecentsTab {
    
    NSMutableArray *uploadsFromDB = [NSMutableArray new];
    
    [uploadsFromDB addObjectsFromArray:[ManageUploadsDB getUploadsWithErrorByStatus:errorUploading]];
    
    
    
    UploadsOfflineDto *uploadOffline = nil;
    //for in
    for(uploadOffline in uploadsFromDB) {
        //Create the object
        ManageUploadRequest *currentManageUploadRequest = [ManageUploadRequest new];
        
        //Insert the specific data to recents view
        NSDate *uploadedDate = [NSDate dateWithTimeIntervalSince1970:uploadOffline.uploadedDate];
        currentManageUploadRequest.date = uploadedDate;
        //Set uploadOffline
        currentManageUploadRequest.currentUpload = uploadOffline;
        currentManageUploadRequest.lenghtOfFile = [UploadUtils makeLengthString:uploadOffline.estimateLength];
        currentManageUploadRequest.userUploading = [ManageUsersDB getUserByIdUser:uploadOffline.userId];
        
        currentManageUploadRequest.pathOfUpload = [UtilsUrls getPathWithAppNameByDestinyPath:uploadOffline.destinyFolder andUser:currentManageUploadRequest.userUploading];
        
        //Add the object to the array
        [self addToTheUploadArrayWithoutDuplicatesTheFile:currentManageUploadRequest];
    }
}


- (void) addPendingToCheckUploadsToRecentsTab {
    
    NSMutableArray *uploadsFromDB = [NSMutableArray new];
    
    [uploadsFromDB addObjectsFromArray:[ManageUploadsDB getUploadsByStatus:pendingToBeCheck andByKindOfError:notAnError]];
    
    UploadsOfflineDto *uploadOffline = nil;
    //for in
    for(uploadOffline in uploadsFromDB) {
        //Create the object
        ManageUploadRequest *currentManageUploadRequest = [ManageUploadRequest new];
        
        //Insert the specific data to recents view
        NSDate *uploadedDate = [NSDate dateWithTimeIntervalSince1970:uploadOffline.uploadedDate];
        currentManageUploadRequest.date = uploadedDate;
        //Set uploadOffline
        currentManageUploadRequest.currentUpload = uploadOffline;
        currentManageUploadRequest.lenghtOfFile = [UploadUtils makeLengthString:uploadOffline.estimateLength];
        currentManageUploadRequest.userUploading = [ManageUsersDB getUserByIdUser:uploadOffline.userId];
        
        currentManageUploadRequest.pathOfUpload = [UtilsUrls getPathWithAppNameByDestinyPath:uploadOffline.destinyFolder andUser:currentManageUploadRequest.userUploading];
        
        //Add the object to the array
        [self addToTheUploadArrayWithoutDuplicatesTheFile:currentManageUploadRequest];
    }
}


/*
 * Method that relaunch upload failed without timeout
 */
- (void) relaunchUploadsFailedForced{
    [self relaunchUploadsFailed:YES];
}

/*
 * Method that relaunch upload failed with timeout
 */
- (void) relaunchUploadsFailedNoForced{
    [self relaunchUploadsFailed:NO];
}

/*
 * Method relaunch the upload failed if exist
 * This method has a timeout
 *@isForced -> If YES the timeout is 0 secs
 */
- (void) relaunchUploadsFailed:(BOOL)isForced {
    
    long currentDate = [[NSDate date] timeIntervalSince1970];
    //DLog(@"currentDate - _dateLastRelaunch: %ld", currentDate - _dateLastRelaunch);
    
    if ((currentDate - _dateLastRelaunch) > k_minimun_time_to_relaunch || isForced) {
        
        _dateLastRelaunch = currentDate;
        
        //We get all the files that are with any error
        NSMutableArray *listOfUploadsFailed = [ManageUploadsDB getUploadsByStatus:errorUploading andByKindOfError:notAnError];
        NSMutableArray *listOfPendingToBeCheckFiles = [ManageUploadsDB getUploadsByStatus:pendingToBeCheck andByKindOfError:notAnError];
        DLog(@"There are: %ld in the list of uploads failed", (long)listOfUploadsFailed.count);
        DLog(@"There are: %ld files in the list of pending to be check", (long)listOfPendingToBeCheckFiles.count);
        
        //First, check if there are
        if (listOfUploadsFailed.count > 0) {
            //We update all the files with error to the status waitingAddToUploadList
            [ManageUploadsDB updateAllErrorUploadOfflineWithWaitingAddUploadList];
            
            
            if (_prepareFiles == nil) {
                _prepareFiles = [[PrepareFilesToUpload alloc] init];
                _prepareFiles.listOfFilesToUpload = [[NSMutableArray alloc] init];
                _prepareFiles.listOfAssetsToUpload = [[NSMutableArray alloc] init];
                _prepareFiles.arrayOfRemoteurl = [[NSMutableArray alloc] init];
                _prepareFiles.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
                _prepareFiles.delegate = self;
            }
            
            for (UploadsOfflineDto *upload in listOfUploadsFailed) {
                upload.status=waitingAddToUploadList;
            }
            
            
            
            [_prepareFiles sendFileToUploadByUploadOfflineDto:[listOfUploadsFailed objectAtIndex:0]];
        }
        

        if (listOfPendingToBeCheckFiles.count > 0) {
            [self checkTheUploadFilesOnTheServer:listOfPendingToBeCheckFiles];
        }
        
        
    }

}

/*
 * Method called when the app starts or when back for the background.
 * This method pust the files modified by the document provider to upload.
 */
- (void) launchUploadsOfflineFromDocumentProvider{
    
    NSMutableArray *listOfFilesGeneratedByDocumentProvider = [ManageUploadsDB getUploadsByStatus:generatedByDocumentProvider andByKindOfError:notAnError];
    
    if (listOfFilesGeneratedByDocumentProvider.count > 0) {
        [ManageUploadsDB updateUploadsGeneratedByDocumentProviertoToWaitingAddUploadList];
        
        if (_prepareFiles == nil) {
            _prepareFiles = [[PrepareFilesToUpload alloc] init];
            _prepareFiles.listOfFilesToUpload = [[NSMutableArray alloc] init];
            _prepareFiles.arrayOfRemoteurl = [[NSMutableArray alloc] init];
            _prepareFiles.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
            _prepareFiles.delegate = self;
        }
        
      
        for (UploadsOfflineDto *upload in listOfFilesGeneratedByDocumentProvider) {
            upload.status = waitingAddToUploadList;
        }
        
        self.isOverwriteProcess = YES;
        
        [_prepareFiles sendFileToUploadByUploadOfflineDto:[listOfFilesGeneratedByDocumentProvider objectAtIndex:0]];
        
 
    }
}


///-----------------------------------
/// @name getTheWaitingUpload
///-----------------------------------

/**
 * This method gets the waiting to upload files if there are no uploading files
 *
 * @return NSMutableArray -> An array with waiting to upload files
 */
- (NSMutableArray *)getTheWaitingUpload {
    
    NSMutableArray *uploadingFilesArray = [NSMutableArray new];
    NSMutableArray *waitingFilesArray = [NSMutableArray new];
    
    for (ManageUploadRequest *uploadFile in _uploadArray) {
        if (uploadFile.currentUpload.status == uploading) {
            [uploadingFilesArray addObject:uploadFile];
        }
    }
    
    if ([uploadingFilesArray count] == 0) {
        for (ManageUploadRequest *uploadFile in _uploadArray) {
            if (uploadFile.currentUpload.status == waitingForUpload) {
                [waitingFilesArray addObject:uploadFile];
            }
        }
    }
    return waitingFilesArray;
}




- (void) removeFromTabRecentsAllInfoByUser:(UserDto *)user {
    
    DLog(@"_uploadArray count: %ld", (long)[_uploadArray count]);
    
    NSMutableArray *arrayOfPositionsToDelete = [NSMutableArray new];
    
    //We remove from the _uploadArray all the files from user
    for (int i = 0 ; i < [_uploadArray count] ; i++) {
        
        DLog(@"Position: %d", i);
        
        ManageUploadRequest *current = [_uploadArray objectAtIndex:i];
        
        if (current.currentUpload.userId == user.idUser) {
            [arrayOfPositionsToDelete addObject:[NSNumber numberWithInt:i]];
        }
    }
    
    
    NSArray *arrayReverse = [[arrayOfPositionsToDelete reverseObjectEnumerator] allObjects];
    
    for (NSNumber *currentNumber in arrayReverse) {
        [_uploadArray removeObjectAtIndex:[currentNumber integerValue]];
    }
    
    //Refresh the tab
    [self updateRecents];
}

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
- (void) cancelTheCurrentUploadsOfTheUser:(NSInteger)idUser{
    
    //Check the currents uploads from a user
    NSArray *uploadsArray = [NSArray arrayWithArray:_uploadArray];
    
    ManageUploadRequest *currentManageUploadRequest = nil;
    
    for (id obj in uploadsArray) {
        
        currentManageUploadRequest=obj;
        
        if (currentManageUploadRequest.currentUpload.kindOfError == notAnError && currentManageUploadRequest.currentUpload.status != uploaded && currentManageUploadRequest.currentUpload.userId == idUser) {
            //Indicate Error Credentials
            [currentManageUploadRequest changeTheStatusToFailForCredentials];
        }
    }
    
}


///-----------------------------------
/// @name Change the Status in uploads with Credential Error 
///-----------------------------------

/**
 * This method is called after that this class receive the notification that the user
 * has resolved the credentials error.
 * In this method we changed the kind of error of uploads failed "errorCredentials" to "notAndError"
 * for a specific user
 *
 * @param idUser -> idUser for a scpecific user.
 *
 * @discussion Maybe could be better move this kind of method to a singleton class inicializate in appDelegate.
 *
 */
- (void)changeTheStatusOfCredentialsFilesErrorOfAnUserId:(NSInteger)idUser{
    
    __block ManageUploadRequest *currentManageUploadRequest;
    
    NSArray *failedUploadsTemp = [NSArray arrayWithArray:_uploadArray];
    
    [failedUploadsTemp enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        currentManageUploadRequest = obj;
        
        if (currentManageUploadRequest.currentUpload.kindOfError == errorCredentials && currentManageUploadRequest.currentUpload.userId == idUser) {
            DLog(@"ub with name %@ not an error", currentManageUploadRequest.currentUpload.uploadFileName);
            currentManageUploadRequest.currentUpload.kindOfError=notAnError;
            [ManageUploadsDB setStatus:currentManageUploadRequest.currentUpload.status andKindOfError:notAnError byUploadOffline:currentManageUploadRequest.currentUpload];
        }
    }];
}

- (void) changeUploadsToWaitingForServerConnection{
    
    if (self.uploadArray.count > 0) {
        
        NSArray *uploadsTemp = [NSArray arrayWithArray:self.uploadArray];
        
        for (ManageUploadRequest *upload in uploadsTemp) {
      
            if (upload.currentUpload.status != uploaded && upload.currentUpload.status != errorUploading) {
                 [upload changeTheStatusToWaitingToServerConnection];
            }
        }
        
        [self.recentViewController updateRecents];
    }
}

///-----------------------------------
/// @name moveIfIsNecessaryFolderOfOwnCloudFromContainerAppSandboxToAppGroupSanbox
///-----------------------------------

/**
 * This method updates to move the Sandbox of the app to the Shared Sanbox of the AppGroup to be used on the Document Provider
 */
- (void) moveIfIsNecessaryFolderOfOwnCloudFromContainerAppSandboxToAppGroupSanbox {
    
    NSString *folderToBeMoved = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    folderToBeMoved = [NSString stringWithFormat:@"%@/%@",folderToBeMoved, k_owncloud_folder];
    
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:folderToBeMoved isDirectory:&isDir];
    
    if (exists) {
        if (isDir) {
            NSString *folderDestiny = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[UtilsUrls getBundleOfSecurityGroup]] path];
            folderDestiny = [NSString stringWithFormat:@"%@/%@",folderDestiny, k_owncloud_folder];
            
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:folderToBeMoved toPath:folderDestiny error:&error];
            
            if(error) {
                DLog(@"Error: %@", error);
            }
        }
    }
}

//-----------------------------------
/// @name reloadTableFromDataBaseIfFileIsVisibleOnList
///-----------------------------------

/**
 * Method that check if the file is visible on the file list before reload the table from the database
 *
 * @param file -> FileDto visible
 */
- (void) reloadTableFromDataBaseIfFileIsVisibleOnList:(FileDto *) file {
    
    //Update the file and folder to be sure that the ids are right
    FileDto *folder = [ManageFilesDB getFileDtoByFileName:self.presentFilesViewController.fileIdToShowFiles.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.presentFilesViewController.fileIdToShowFiles.filePath andUser:self.activeUser] andUser:self.activeUser];
    file = [ManageFilesDB getFileDtoByFileName:file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:self.activeUser] andUser:self.activeUser];
    
    if (folder.idFile == file.fileId) {
        [_presentFilesViewController reloadTableFromDataBase];
    }
}

- (void) reloadCellByFile:(FileDto *) file {
    
    //Update the file and folder to be sure that the ids are right
    FileDto *folder = [ManageFilesDB getFileDtoByFileName:self.presentFilesViewController.fileIdToShowFiles.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.presentFilesViewController.fileIdToShowFiles.filePath andUser:self.activeUser] andUser:self.activeUser];
    file = [ManageFilesDB getFileDtoByFileName:file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:self.activeUser] andUser:self.activeUser];
    
    if (folder.idFile == file.fileId) {
        [_presentFilesViewController reloadCellByFile:file];
    }
}

- (void) reloadCellByUploadOffline:(UploadsOfflineDto *) uploadOffline {
    
    //Update the file and folder to be sure that the ids are right
    FileDto *folder = [ManageFilesDB getFileDtoByFileName:self.presentFilesViewController.fileIdToShowFiles.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.presentFilesViewController.fileIdToShowFiles.filePath andUser:self.activeUser] andUser:self.activeUser];
    FileDto *file = [ManageFilesDB getFileDtoByFileName:uploadOffline.uploadFileName andFilePath:[UtilsUrls getFilePathOnDBByFullPath:uploadOffline.destinyFolder andUser:self.activeUser] andUser:self.activeUser];
    
    if (folder.idFile == file.fileId) {
        [_presentFilesViewController reloadCellByFile:file];
    }
}

///-----------------------------------
/// @name reloadCellByKey
///-----------------------------------

/**
 * This method refresh the folder cell if is visible
 *
 * @param key -> key,
 */
-(void)reloadCellByKey:(NSString *)key{
    
    //Refresh list to update the arrow
    NSString *folderToRemovePath;
    NSString *folderToRemoveName = [NSString stringWithFormat:@"%@/",[key lastPathComponent]];
    NSString *parentKey = [key substringToIndex:[key length] - ([key lastPathComponent].length+1)];
    if (![parentKey hasSuffix:@"/"]) {
        parentKey = [parentKey stringByAppendingString:@"/"];
    }
    if ([parentKey isEqualToString:@"/"]) {
        folderToRemovePath = @"";
    } else {
        folderToRemovePath = parentKey;
    }
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    FileDto *folderRemoved = [ManageFilesDB getFileDtoByFileName:[folderToRemoveName encodeString:NSUTF8StringEncoding] andFilePath:[folderToRemovePath encodeString:NSUTF8StringEncoding] andUser:app.activeUser];
    [self reloadCellByFile:folderRemoved];
}
- (void) showLoginView {
    DLog(@"ShowLoginView");
    
    self.loginWindowViewController = [[LoginViewController alloc] initWithLoginMode:LoginModeCreate];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.window.rootViewController = self.loginWindowViewController;
    [self.window makeKeyAndVisible];
}

#pragma mark - SplashScreenFake

- (void) showSplashScreenFake {
    
    DLog(@"showSplashScreenFake");
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Launch Screen" bundle:nil];
    UIViewController *splashScreenView = [storyboard instantiateViewControllerWithIdentifier:@"SplashScreen"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.window.rootViewController = splashScreenView;
    [self.window makeKeyAndVisible];
}

#pragma mark - CheckAccessToServerDelegate

-(void)connectionToTheServer:(BOOL)isConnection {
    ((CheckAccessToServer*)[CheckAccessToServer sharedManager]).delegate = nil;
    [self checkIfIsNecesaryShowPassCode];
}
-(void)repeatTheCheckToTheServer {
    ((CheckAccessToServer*)[CheckAccessToServer sharedManager]).delegate = nil;
    [self checkIfIsNecesaryShowPassCode];
}
-(void)badCertificateNoAcceptedByUser {
    ((CheckAccessToServer*)[CheckAccessToServer sharedManager]).delegate = nil;
    [self checkIfIsNecesaryShowPassCode];
}

@end
