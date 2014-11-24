//
//  SelectFolderViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 28/09/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "SelectFolderViewController.h"
#import "SelectedFolderCell.h"
#import "FileDto.h"
#import "SelectFolderNavigation.h"
#import "UIColor+Constants.h"
#import "NSString+Encoding.h"
#import "constants.h"
#import "AppDelegate.h"
#import "UIColor+Constants.h"
#import "FileNameUtils.h"
#import "Customization.h"
#import "FileListDBOperations.h"
#import "UtilsDtos.h"
#import "ManageFilesDB.h"
#import "EditAccountViewController.h"
#import "DetailViewController.h"
#import "OCNavigationController.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "UtilsUrls.h"

@interface SelectFolderViewController ()

@end

@implementation SelectFolderViewController
@synthesize createButton=_createButton;
@synthesize chooseButton=_chooseButton;
@synthesize folderTableView=_folderTableView;
@synthesize toolBarLabel=_toolBarLabel;
@synthesize toolBar=_toolBar;
@synthesize sortedArray=_sortedArray;
@synthesize currentDirectoryArray=_currentDirectoryArray;
@synthesize mUser=_mUser;
@synthesize currentLocalFolder=_currentLocalFolder;
@synthesize currentRemoteFolder=_currentRemoteFolder;
@synthesize nextRemoteFolder=_nextRemoteFolder;
@synthesize mCheckAccessToServer=_mCheckAccessToServer;
@synthesize fileIdToShowFiles=_fileIdToShowFiles;
@synthesize selectedFileDto=_selectedFileDto;
@synthesize parent;
@synthesize folderView=_folderView;
@synthesize toolBarLabelTxt = _toolBarLabelTxt;
@synthesize alert = _alert;

#pragma mark init methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{      
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization   
        if(self.mCheckAccessToServer == nil) {
            self.mCheckAccessToServer = [[CheckAccessToServer alloc] init];
            self.mCheckAccessToServer.delegate = self;
        }
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        self.fileIdToShowFiles=[ManageFilesDB getRootFileDtoByUser:app.activeUser];
    }
    return self;
}

- (id) initWithNibName:(NSString *) nibNameOrNil onFolder:(NSString *) currentFolder andFileId:(int) fileIdToShowFiles andCurrentLocalFolder:(NSString *)currentLocalFoler
{
    self.currentRemoteFolder = currentFolder;
    DLog(@"self.currentRemoteFolder: %@", self.currentRemoteFolder);
    self.fileIdToShowFiles = [ManageFilesDB getFileDtoByIdFile:fileIdToShowFiles];
    self.currentLocalFolder = currentLocalFoler;
    
    DLog(@"self.currentLocalFolder: %@", self.currentLocalFolder);
    
    if(self.mCheckAccessToServer == nil) {
        self.mCheckAccessToServer = [[CheckAccessToServer alloc] init];
        self.mCheckAccessToServer.delegate = self;
    }
    
    DLog(@"currentRemoteFolder: %@ and fileIdToShowFiles: %d", currentFolder, self.fileIdToShowFiles.idFile);
    
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    return self;
}

#pragma mark load view life

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    //If it is the root folder show the icon/name of root folder
    if(self.fileIdToShowFiles.isRootFolder) {
        UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:[FileNameUtils getTheNameOfTheBrandImage]]];
        
        if(k_show_logo_on_title_file_list) {
            self.navigationItem.titleView=imageView;
        } else {
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            self.navigationItem.title = appName;
        }
    }
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
	[self.navigationItem setRightBarButtonItem:cancelButton];
    
    _toolBarLabel.text = self.toolBarLabelTxt;
    
    _createButton.title=NSLocalizedString(@"create_button", nil);
    _chooseButton.title=NSLocalizedString(@"choose_button", nil);
    
    //If the default langauge is german we change the size of letter on iphone portrait only
    [self configTheBottomLabelIfIsGermanLanguageInIPhone];    
    
    _toolBarLabel.textColor=[UIColor colorOfNavigationTitle];
    //Store the current active user
    self.mUser = app.activeUser;
    
    [self reloadTableFromDataBase];
    
    //Set the observers of the notifications
    [self setNotificationForCommunicationBetweenViews];

}

-(void)viewDidLayoutSubviews
{
    
    if (IS_IOS8) {
        if ([self.folderTableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.folderTableView setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, 0)];
        }
        
        if ([self.folderTableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.folderTableView setLayoutMargins:UIEdgeInsetsZero];
        }
        
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (IS_IOS8) {
        if ([self.folderTableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.folderTableView setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, 0)];
        }
        
        if ([self.folderTableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.folderTableView setLayoutMargins:UIEdgeInsetsZero];
        }
        
    }
}

///-----------------------------------
/// @name Set the notification
///-----------------------------------

/**
 * Set the notification for the communication
 * between diferent views
 */
- (void) setNotificationForCommunicationBetweenViews {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAlertView) name:CloseAlertViewWhenApplicationDidEnterBackground object:nil];
}

///-----------------------------------
/// @name Close the Alert View pop-up
///-----------------------------------

/**
 * Close the alertView pop-up when the app
 * go to background
 */
- (void) closeAlertView {
    [_folderView dismissWithClickedButtonIndex:0 animated:NO];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.currentViewVisible = self;
    
    
    //if is 0 is the root folder
    if(self.fileIdToShowFiles.isRootFolder) {
        
        NSString *currentFolder = [NSString stringWithFormat: @"%@%@", _mUser.url, k_url_webdav_server];
        self.currentRemoteFolder=currentFolder;
        
    } else{
        
        //Is directory
        NSString *folderName =  [self.fileIdToShowFiles.fileName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
        
        //Quit the last character
        folderName = [folderName substringToIndex:[folderName length]-1];
        
        self.navigationItem.title =  folderName;        
        
    }    
    
    //Depend if the navigation is in root folder on not use the image or the folder name.
    if(self.navigationItem.title == nil) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] 
                                       initWithImage:[UIImage imageNamed:[FileNameUtils getTheNameOfTheBrandImage]]
                                       style:UIBarButtonItemStyleBordered 
                                       target:nil 
                                       action:nil];
        
        self.navigationItem.backBarButtonItem = backButton;
    } else {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] 
                                       initWithImage:[UIImage imageNamed:@""]
                                       style:UIBarButtonItemStyleBordered 
                                       target:nil 
                                       action:nil];
        self.navigationItem.backBarButtonItem = backButton;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
   // DLog(@"SelectedFolderView will Rotate");
   
    if (!IS_IPHONE) {
        if (_folderView) {
            [_folderView dismissWithClickedButtonIndex:0 animated:NO];
        }
        
    } else {
        if (toInterfaceOrientation  == UIInterfaceOrientationPortrait) {
        } else {
            if (IS_IPHONE) {
                //Cancel TSAlert View of Create Folder and Close keyboard
                if (_folderView) {
                    [_folderView dismissWithClickedButtonIndex:0 animated:NO];
                }
                
                if (_alert) {
                    [_alert dismissWithClickedButtonIndex:0 animated:NO];
                }
            }
        }
    }
    
     [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];    
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    //If the default langauge is german we change the size of letter on iphone portrait only
    [self configTheBottomLabelIfIsGermanLanguageInIPhone];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

/*
 * This method configure the bottom label (_toolBarLabel) in the case of german language on iPhone only.
 * Different font size in portrait and landscape
 */
- (void) configTheBottomLabelIfIsGermanLanguageInIPhone{
    
    if (IS_PORTRAIT) {
        
        if (IS_IPHONE) {
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
            NSString *currentLanguage = [languages objectAtIndex:0];
            
            if ([currentLanguage isEqualToString:@"de"]) {
                [_toolBarLabel setFont:[UIFont boldSystemFontOfSize:11.0]];
            }
        }
        
    }else{
        
        if (IS_IPHONE) {
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
            NSString *currentLanguage = [languages objectAtIndex:0];
            
            if ([currentLanguage isEqualToString:@"de"]) {
                [_toolBarLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
            }
        }
    }
    
}


#pragma mark Action Buttons

/*
 * Method that remove this view
 */

- (void)cancel{
    
    if (_alert) {
        _alert = nil;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

/*
 * Method that inform to the controller of the folder selected by user.
 */
- (IBAction)chooseFolder{
    
    if (_alert) {
        _alert = nil;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
   DLog(@"Current remote folder: %@", self.currentRemoteFolder);
    
   [(SelectFolderNavigation*)self.parent selectFolder:self.currentRemoteFolder];    

}

#pragma mark Reload Methods
/*
 * Method that reload the data of the tableview with the database data.
 */
-(void)reloadTableFromDataBase {
    
    NSArray *temp = [ManageFilesDB getFilesByFileIdForActiveUser:self.fileIdToShowFiles.idFile];
    NSMutableArray *onlyFolders = [[NSMutableArray alloc]init];
    
    FileDto *fileTemp=nil;
    //Only stores folders
    for (int i=0; i<[temp count]; i++) {
        
        fileTemp = [temp objectAtIndex:i];
        
        if ([fileTemp isDirectory]==YES) {
            [onlyFolders addObject:fileTemp];
        }
    }    
    
    self.currentDirectoryArray = onlyFolders;    
    //Sorted the files array with the selector "fileName"
    self.sortedArray = [self partitionObjects: self.currentDirectoryArray collationStringSelector:@selector(fileName)];  
    [_folderTableView reloadData];
    
}

/*
 * Method that launch the method to reload de data of database with the server data.
 */
- (void)refreshTableFromWebDav {
    [self performSelector:@selector(sendRequestToReloadTableView) withObject:nil];
}

/*
 * Method that send a request to the server to get the data.
 */
- (void)sendRequestToReloadTableView {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    NSString *path = _currentRemoteFolder;
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[AppDelegate sharedOCCommunication] readFolder:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        DLog(@"Operation response code: %d", response.statusCode);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            
            //Pass the items with OCFileDto to FileDto Array
            NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
            [self deleteOldDataFromDBBeforeRefresh:directoryList];
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %d", response.statusCode);
        [self manageServerErrors:response.statusCode and:error];
    }];

}

-(void)deleteOldDataFromDBBeforeRefresh:(NSArray *) requestArray {
    
    NSMutableArray *directoryList = [NSMutableArray arrayWithArray:requestArray];
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    //Change the filePath from the library to our format
    for (FileDto *currentFile in directoryList) {
        //Remove part of the item file path
        NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser];
        if([currentFile.filePath length] >= [partToRemove length]){
            currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
        }
    }
    
   // DLog(@"The directory List have: %d elements", directoryList.count);
    
   // DLog(@"Directoy list: %@", directoryList);
    
    // NSMutableArray *directoryList = [[req getDirectoryList] mutableCopy];
    self.currentDirectoryArray = [FileListDBOperations makeTheRefreshProcessWith:directoryList inThisFolder:self.fileIdToShowFiles.idFile];
    
    [FileListDBOperations createAllFoldersByArrayOfFilesDto:self.currentDirectoryArray andLocalFolder:self.currentLocalFolder];
    
    //Only folders
    NSArray *temp = self.currentDirectoryArray;
    NSMutableArray *onlyFolders = [[NSMutableArray alloc]init];
    
    FileDto *fileTemp;
    
    for (int i=0; i<[temp count]; i++) {
        fileTemp = [temp objectAtIndex:i];
        if ([fileTemp isDirectory]==YES) {
            [onlyFolders addObject:fileTemp];
        }
    }
    
    self.currentDirectoryArray = onlyFolders;
    
    //Sorted the files array
    self.sortedArray = [self partitionObjects: self.currentDirectoryArray collationStringSelector:@selector(fileName)];
    
    [_folderTableView reloadData];
    [self endLoading];
    
}

#pragma mark Loading view methods

/*
 * Method that launch the loading screen and block the view
 */
-(void)initLoading {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"loading", nil);
    
    if (IS_IPHONE) {
        hud.dimBackground = YES;
        
    }else {
        hud.dimBackground = NO;
        
    }
    
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.toolBar.userInteractionEnabled = NO;
}

/*
 * Method that quit the loading screen and unblock the view
 */
- (void)endLoading {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.toolBar.userInteractionEnabled = YES;
}

#pragma mark - Order method

/*
 * Method that sorts alphabetically array by selector
 *@array -> array of sections and rows of tableview
 */

- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector
{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++)
    {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    
    //put each object into a section
    for (id object in array)
    {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }
    
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //sort each section
    for (NSMutableArray *section in unsortedSections)
    {
        [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
    }
    
    return sections;
}

#pragma mark - Create Folder

/*
 * This method show an pop up view to create folder
 */
- (IBAction)showCreateFolder{
    
    _folderView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"create_folder", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"save", nil), nil];
    _folderView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_folderView textFieldAtIndex:0].delegate = self;
    [[_folderView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
    [[_folderView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    [_folderView show];
}

/*
 * This method check for the folder with the same name that the user want create.
 * @string -> in the string to compare
 */

-(BOOL)checkForSameName:(NSString *)string
{
    string = [string stringByAppendingString:@"/"];
    string = [string stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
    DLog(@"string: %@",string);
    NSString *dicName;
    FileDto *fileDto=nil;
    
    for (int i=0; i<[_currentDirectoryArray count]; i++) {
        
        fileDto = [_currentDirectoryArray objectAtIndex:i];       
        
        //DLog(@"%@", fileDto.fileName);
        dicName=fileDto.fileName;      
        
        if([string isEqualToString:dicName])
        {
            return YES;
        }
        
    }
    return NO;
}

/*
 * This method create new folder in path
 */
-(void) newFolderSaveClicked:(NSString*)name {
    
    //Check if the folder name has "/"
    BOOL thereAreForbidenCharacters = NO;
    for(int i = 0 ;i < [name length]; i++) {
        if ([name characterAtIndex:i] == '/'){
            thereAreForbidenCharacters = YES;
        }
    }
    if (!thereAreForbidenCharacters) {
        
        //Check if exist a folder with the same name
        if ([self checkForSameName:name] == NO) {
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            NSString *newURL = [NSString stringWithFormat:@"%@%@",self.currentRemoteFolder,[name encodeString:NSUTF8StringEncoding]];
            NSString *rootPath = [UtilsDtos getDbBFilePathFromFullFilePath:newURL andUser:app.activeUser];
            
            //Set the right credentials
            if (k_is_sso_active) {
                [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
            } else if (k_is_oauth_active) {
                [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
            } else {
                [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
            }
            
            NSString *pathOfNewFolder = [NSString stringWithFormat:@"%@%@",[_currentRemoteFolder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], name ];
            
            [[AppDelegate sharedOCCommunication] createFolder:pathOfNewFolder onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                DLog(@"Folder created");
                BOOL isSamlCredentialsError=NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active && redirectedServer) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                    if (isSamlCredentialsError) {
                        [self errorLogin];
                    }
                }
                if (!isSamlCredentialsError) {
                
                    //Obtain the path where the folder will be created in the file system
                    NSString *currentLocalFileToCreateFolder = [NSString stringWithFormat:@"%@/%d/%@",[UtilsUrls getOwnCloudFilePath],app.activeUser.idUser,[rootPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

                    
                    DLog(@"Name of the folder: %@ to create in: %@",name, currentLocalFileToCreateFolder);
                    
                    //Create the new folder in the file system
                    [FileListDBOperations createAFolder:name inLocalFolder:currentLocalFileToCreateFolder];
                    [self refreshTableFromWebDav];
                }
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
                DLog(@"error: %@", error);
                DLog(@"Operation error: %d", response.statusCode);
                [self manageServerErrors:response.statusCode and:error];
            } errorBeforeRequest:^(NSError *error) {
                if (error.code == OCErrorForbidenCharacters) {
                    [self endLoading];
                    DLog(@"The folder have problematic characters");
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"forbiden_characters", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    [alert show];
                }
            }];
        } else {
            [self endLoading];
            DLog(@"Exist a folder with the same name");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"folder_exist", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alert show];
        }
    } else {
        [self endLoading];
        DLog(@"The folder have problematic characters");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"forbiden_characters", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
}


/*
 * Show the standar message of the error connection.
 */
- (void)showErrorConnectionPopUp{
    _alert = nil;
    _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil)
                                                    message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [_alert show];

    
}

#pragma mark - UIAlertViewDelegate

- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex{

    DLog(@"Selected");
    
   // UIView* firstResponder = [keyWindow performSelector:@selector(firstResponder)];
   // [_folderView.inputTextField resignFirstResponder];
    
    // cancel
    if( buttonIndex == 1 ){
        //Save "Create Folder"
        //Clear the spaces of the left and the right of the sentence
        
        NSString* result = [[_folderView textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self initLoading];
        [self performSelector:@selector(newFolderSaveClicked:) withObject:result];
        
        
    }else if (buttonIndex == 0) {
        //Cancel 
        
    }else {
        //Nothing
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    BOOL output = YES;
    
    NSString *stringNow = [alertView textFieldAtIndex:0].text;
    
    
    //Active button of folderview only when the textfield has something.
    NSString *rawString = stringNow;
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
    
    if ([trimmed length] == 0) {
        // Text was empty or only whitespace.
        output = NO;
    }
    
    //Button save disable when the textfield is empty
    if ([stringNow isEqualToString:@""]) {
        output = NO;
    }
    
    return output;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    DLog(@"textFieldShouldReturn");
    [textField resignFirstResponder];    
    return YES;
}

#pragma mark - UITableView datasource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
     return [[self.sortedArray objectAtIndex:section] count];
}

// Returns the table view managed by the controller object.
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //Only show the section title if there are rows in it
    BOOL showSection = [[self.sortedArray objectAtIndex:section] count] != 0;
    NSArray *titles = [[UILocalizedIndexedCollation currentCollation] sectionTitles];
    
    if(k_minimun_files_to_show_separators > [self.currentDirectoryArray count]) {
        showSection = NO;
    }
    
    return (showSection) ? [titles objectAtIndex:section] : nil;
}

// Asks the data source to return the titles for the sections for a table view.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if(k_minimun_files_to_show_separators > [self.currentDirectoryArray count]) {
        return nil;
    } else {
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
}

// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    static NSString *CellIdentifier = @"SelectedFolderCell";
    
    SelectedFolderCell *fileCell = (SelectedFolderCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (fileCell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SelectedFolderCell" owner:self options:nil];
        fileCell = (SelectedFolderCell *)[topLevelObjects objectAtIndex:0];
    }
    
    FileDto *file = (FileDto *)[[self.sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    
    //Font for folder
    UIFont *fileFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    fileCell.labelTitle.font = fileFont;
    
    //Is directory
    NSString *folderName =  [file.fileName stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    //Quit the last character
    folderName = [folderName substringToIndex:[folderName length]-1];
    
    //Put the name
    fileCell.labelTitle.text = folderName;
    
    NSString *nameImage = @"folder_icon.png";
    fileCell.fileImageView.image = [UIImage imageNamed:nameImage];
    cell = fileCell;
    
    return cell;
}


#pragma mark - UITableView delegate

// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; 
    
    FileDto *selectedFile = (FileDto *)[[self.sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    [self initLoading];
    [self goToFolder:selectedFile];

}


#pragma mark Navigation folder methods

//we search data to navigate to the clicked folder
- (void) goToFolder:(FileDto *) selectedFile {
    
    DLog(@"self.currentLocalFolder: %@",self.currentLocalFolder);
    
    NSMutableArray *allFiles = [ManageFilesDB getFilesByFileIdForActiveUser:selectedFile.idFile];
    
    //Only folders
    NSArray *splitedUrl = [self.mUser.url componentsSeparatedByString:@"/"];
    self.nextRemoteFolder = [NSString stringWithFormat:@"%@//%@%@", [splitedUrl objectAtIndex:0], [splitedUrl objectAtIndex:2], [NSString stringWithFormat:@"%@%@",selectedFile.filePath,selectedFile.fileName]];
    
    self.currentLocalFolder = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, selectedFile.fileName];
    DLog(@"self.nextRemoteFolder: %@", self.nextRemoteFolder);
    
    //if no files we ask for it else go to the next folder
    if([allFiles count] <= 0) {
        
        self.selectedFileDto =selectedFile;
        
        if ([_mCheckAccessToServer isNetworkIsReachable]){
            [self goToFolderWithoutCheck];
        } else {
            _alert = nil;
            _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [_alert show];
            [self endLoading];
        }
    } else {
        [self navigateToUrl:self.nextRemoteFolder andFileId:selectedFile.idFile];
    }
}

-(void) goToFolderWithoutCheck {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    NSString *path = _nextRemoteFolder;
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[AppDelegate sharedOCCommunication] readFolder:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        DLog(@"Operation response code: %d", response.statusCode);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            //Pass the items with OCFileDto to FileDto Array
            NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
            [self prepareForNavigationWithData:directoryList];
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %d", response.statusCode);
        [self manageServerErrors:response.statusCode and:error];
        
    }];

}
-(void)navigateToUrl:(NSString *) url andFileId:(int)fileIdToShowFiles {
    
    DLog(@"url: %@", url);
    
    SelectFolderViewController *sf = [[SelectFolderViewController alloc]initWithNibName:@"SelectFolderViewController" onFolder:url andFileId:fileIdToShowFiles andCurrentLocalFolder:self.currentLocalFolder];
    sf.folderView = _folderView;
    sf.toolBarLabelTxt = self.toolBarLabelTxt;
    sf.toolBarLabel.textColor = [UIColor colorOfNavigationTitle];
    
    sf.parent=parent;
    
   [[self navigationController] pushViewController:sf animated:YES];
    [self endLoading];
}

/*
 * Method that recevie NSData from the request and parse
 * this data with XML parser and get the directory array
 * @req --> NSArray of the request
 */

-(void)prepareForNavigationWithData:(NSArray *) requestArray {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
   // DLog(@"idFile: %d", self.selectedFileDto.idFile);
   // DLog(@"name: %@", self.selectedFileDto.fileName);
   // DLog(@"self.nextRemoteFolder: %@", self.nextRemoteFolder);
    
    _selectedFileDto = [ManageFilesDB getFileDtoByFileName:_selectedFileDto.fileName andFilePath:[UtilsDtos getFilePathOnDBFromFilePathOnFileDto:_selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    NSMutableArray *directoryList = [NSMutableArray arrayWithArray:requestArray];
    
    //Change the filePath from the library to our format
    for (FileDto *currentFile in directoryList) {
        //Remove part of the item file path
        NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser];
        if([currentFile.filePath length] >= [partToRemove length]){
            currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
        }
    }
    
   // DLog(@"The directory List have: %d elements", directoryList.count);
    
   // DLog(@"Directoy list: %@", directoryList);
    
    [ManageFilesDB insertManyFiles:directoryList andFileId:self.selectedFileDto.idFile];
    
    [self navigateToUrl:self.nextRemoteFolder andFileId:self.selectedFileDto.idFile];
    
    
}

#pragma mark - Server connect methods

/*
 * Method called when receive a fail from server side
 * @errorCodeFromServer -> WebDav Server Error of NSURLResponse
 * @error -> NSError of NSURLConnection
 */

- (void)manageServerErrors: (NSInteger *)errorCodeFromServer and:(NSError *)error{
    
    int code = errorCodeFromServer;
    
    DLog(@"Error code from  web dav server: %d", code);
    DLog(@"Error code from server: %d", error.code);
    
    [self endLoading];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Server connection error
    switch (error.code) {
        case NSURLErrorServerCertificateUntrusted: //-1202
            [self.mCheckAccessToServer isConnectionToTheServerByUrl:app.activeUser.url];
            break;
            
        default:
            //Web Dav Error Code
            switch (code) {
                case kOCErrorServerUnauthorized:
                    //Unauthorized (bad username or password)
                    [self errorLogin];
                    break;
                case kOCErrorServerForbidden:
                    //403 Forbidden
                    [self showError:NSLocalizedString(@"error_not_permission", nil)];
                    break;
                case kOCErrorServerPathNotFound:
                    //404 Not Found. When for example we try to access a path that now not exist
                    [self showError:NSLocalizedString(@"error_path", nil)];
                    break;
                case kOCErrorServerMethodNotPermitted:
                    //405 Method not permitted
                    [self showError:NSLocalizedString(@"not_possible_create_folder", nil)];
                    break;
                case kOCErrorServerTimeout:
                    //408 timeout
                    [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                    break;
                default:
                    [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                    break;
            }
            break;
    }
    
}

/*
 * Method called when there are a fail connection with the server
 * @errorCode -> Server error code to select the correct msg
 */
- (void)showError:(NSString *) message {
    
    _alert = nil;
    _alert = [[UIAlertView alloc] initWithTitle:message
                                                    message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [_alert show];
    
}


/*
 * Method calle when there are a fail connection with the server
 */
- (void)manageFailOfServerConnection{
    
    _alert = nil;
    _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil)
                                                    message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [_alert show];
}


-(void) errorLogin {
    [self endLoading];
    
    DLog(@"Error Login");
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //In SAML the error message is about the session expired
    if (k_is_sso_active) {
        [self performSelectorOnMainThread:@selector(showAlertView:)
                               withObject:NSLocalizedString(@"session_expired", nil)
                            waitUntilDone:YES];
    } else {
        [self performSelectorOnMainThread:@selector(showAlertView:)
                               withObject:NSLocalizedString(@"error_login_message", nil)
                            waitUntilDone:YES];
    }
    
    //Edit Account
    EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:app.activeUser];
    [viewController setBarForCancelForLoadingFromModal];
    
    if (IS_IPHONE) {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else {
        
        if (IS_IOS8) {
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
        }
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }
}

/*
 * This method is for show alert view in main thread.
 * @string -> string wiht the message of the alert view.
 */

- (void) showAlertView:(NSString*)string{
    
    _alert = nil;
    _alert = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [_alert show];
}


-(void)connectionToTheServer:(BOOL)isConnection {
    
    if(isConnection) {
        DLog(@"Ok, we have connection to the server");
    } else {
        _alert = nil;
        _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil)
                                                        message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [_alert show];
    }
}

-(void)repeatTheCheckToTheServer {
    //ok, certificate accepted
}

-(void)badCertificateNoAcceptedByUser {
    DLog(@"Certificate refushed by user");
}


@end
