//
//  DocumentPickerViewController.m
//  ownCloudExtApp
//
//  Created by Gonzalo Gonzalez on 14/10/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DocumentPickerViewController.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "UserDto.h"
#import "UtilsUrls.h"
#import "FileListDocumentProviderViewController.h"
#import "OCNavigationController.h"
#import "OCCommunication.h"
#import "OCFrameworkConstants.h"
#import "OCURLSessionManager.h"
#import "CheckAccessToServer.h"
#import "OCKeychain.h"
#import "CredentialsDto.h"
#import "FileListDBOperations.h"

@interface DocumentPickerViewController ()

@end

@implementation DocumentPickerViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOwnCloudNavigationOrShowErrorLogin) name:userHasChangeNotification object:nil];
}

- (IBAction)openDocument:(id)sender {
    NSURL* documentURL = [self.documentStorageURL URLByAppendingPathComponent:@"Untitled.txt"];
    
    // TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
    [self dismissGrantingAccessToURL:documentURL];
}

-(void)prepareForPresentationInMode:(UIDocumentPickerMode)mode {
    // TODO: present a view controller appropriate for picker mode here
    
    [self showOwnCloudNavigationOrShowErrorLogin];
    
}

- (void) showOwnCloudNavigationOrShowErrorLogin {
    
    self.user = [ManageUsersDB getActiveUser];
    
    if (self.user) {
        
        FileDto *rootFolder = [ManageFilesDB getRootFileDtoByUser:self.user];
        
        if (!rootFolder) {
            rootFolder = [FileListDBOperations createRootFolderAndGetFileDtoByUser:self.user];
        }
        
        FileListDocumentProviderViewController *fileListTableViewController = [[FileListDocumentProviderViewController alloc] initWithNibName:@"FileListDocumentProviderViewController" onFolder:rootFolder];
        fileListTableViewController.delegate = self;
        
        OCNavigationController *navigationViewController = [[OCNavigationController alloc] initWithRootViewController:fileListTableViewController];

        [self presentViewController:navigationViewController animated:NO completion:^{
            //We check the connection here because we need to accept the certificate on the self signed server before go to the files tab
            CheckAccessToServer *mCheckAccessToServer = [[CheckAccessToServer alloc] init];
            mCheckAccessToServer.viewControllerToShow = fileListTableViewController;
            mCheckAccessToServer.delegate = fileListTableViewController;
            [mCheckAccessToServer isConnectionToTheServerByUrl:self.user.url];
        }];
        
    } else {
        //TODO: show the login view
        NSString *message = NSLocalizedString(@"error_login_doc_provider", nil);
        _labelErrorLogin.text = message;
        _labelErrorLogin.textAlignment = NSTextAlignmentCenter;
        
    }
}


#pragma mark - FMDataBase
+ (FMDatabaseQueue*)sharedDatabase
{
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:@"DB.sqlite"]];
    
    static FMDatabaseQueue* sharedDatabase = nil;
    if (sharedDatabase == nil)
    {
        NSString *documentsDir = [UtilsUrls getOwnCloudFilePath];
        NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"DB.sqlite"];
        
        
        //NSString* bundledDatabasePath = [[NSBundle mainBundle] pathForResource:@"DB" ofType:@"sqlite"];
        sharedDatabase = [[FMDatabaseQueue alloc] initWithPath: dbPath];
    }
    
    return sharedDatabase;
}

#pragma mark - OCCommunications
+ (OCCommunication*)sharedOCCommunication
{
    static OCCommunication* sharedOCCommunication = nil;
    if (sharedOCCommunication == nil)
    {
        sharedOCCommunication = [[OCCommunication alloc] init];
        
        //Acive the cookies functionality if the server supports it

        UserDto *user = [ManageUsersDB getActiveUser];
        
        if (user) {
            if (user.hasCookiesSupport == serverFunctionalitySupported) {
                sharedOCCommunication.isCookiesAvailable = YES;
            }
        }
        
    }
    return sharedOCCommunication;
}

#pragma mark - FileListDocumentProviderViewControllerDelegate

- (void) openFile:(FileDto *)fileDto {
    DLog(@"Open: %@", fileDto.fileName);
}

@end
