//
//  EditFileViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 04/05/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "EditFileViewController.h"
#import "FileNameUtils.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "constants.h"
#import "AppDelegate.h"
#import "UtilsUrls.h"
#import "NSString+Encoding.h"
#import "UploadsOfflineDto.h"
#import "ManageUploadsDB.h"
#import "UtilsFileSystem.h"
#import "UIColor+Constants.h"
#import "UtilsBrandedOptions.h"
#import "UtilsNotifications.h"

#define k_default_extension @"txt"


@interface EditFileViewController ()

@end

@implementation EditFileViewController

- (id)initWithFileDto:(FileDto *)fileDto andModeEditing:(BOOL)modeEditing{
   
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.currentFileDto = fileDto;
        self.isModeEditing = modeEditing;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.titleTextField.placeholder = NSLocalizedString(@"title_text_file_placeholder", nil);

    if (self.isModeEditing) {
        
        self.bodyTextViewHeightConstraint.constant = 2;
        

        
    } else {
        self.titleTextField.text = [NSString stringWithFormat:@"%@.%@",NSLocalizedString(@"default_text_file_title", nil),k_default_extension];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [self.bodyTextView becomeFirstResponder];
    [super viewWillAppear:animated];
    [self setStyleView];
    
}


#pragma mark - Style Methods

- (void) setStyleView {
    
    if (self.isModeEditing) {
        [self.titleTextField setHidden:YES];
        
        self.navigationItem.titleView = [UtilsBrandedOptions getCustomLabelForNavBarByName:[[self.currentFileDto.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
        NSString *contentFile = [NSString stringWithContentsOfFile:[UtilsUrls getFileLocalSystemPathByFileDto:self.currentFileDto andUser:APP_DELEGATE.activeUser] encoding:NSUTF8StringEncoding error:nil];
        self.bodyTextView.text  = contentFile;
        self.initialBodyContent = contentFile;
        
    } else {
        self.navigationItem.title = NSLocalizedString(@"title_view_new_text_file", nil);
        self.initialBodyContent = @"";
    }
    [self setBarButtonStyle];
}

- (void) setBarButtonStyle {
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectDoneView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeViewController)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}


#pragma mark - Action Methods

- (void) didSelectDoneView {
    NSString *fileName = @"";
    NSString *bodyTextFile = @"";
    
    if (self.isModeEditing) {
        fileName = self.currentFileDto.fileName;
    } else {
        fileName = [self.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ];
    }
    bodyTextFile = self.bodyTextView.text;

    
    if ( self.isModeEditing || (!self.isModeEditing && [self isValidTitleName:fileName])) {
        
        if (![self.initialBodyContent isEqualToString:bodyTextFile] || ([bodyTextFile length] == 0)) {
            NSString *tempLocalPath = [self storeFileWithTitle:fileName andBody:bodyTextFile];
            if (tempLocalPath) {
                [self sendTextFileToUploadsByTempLocalPath:tempLocalPath andFileName:fileName];
            }
        } else {
            [self showAlertView:NSLocalizedString(@"no_changes_made", nil)];
        }
        
        [self dismissViewControllerAnimated:NO completion:^{
            //Send notification in order to update the file list
            [[NSNotificationCenter defaultCenter] postNotificationName:IPhoneDoneEditFileTextMessageNotification object:nil];
        }];

    }
    
}

#pragma mark - FilesViewController callBacks



- (void) closeViewController {
    
    [self dismissViewControllerAnimated:true completion:nil];
}


#pragma mark - Check title name

- (BOOL) existFileWithSameName:(NSString*)fileName {
    
    BOOL sameName = NO;
    
    self.currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:self.currentFileDto.idFile];

    NSPredicate *predicateSameFileName = [NSPredicate predicateWithFormat:@"fileName == %@", [fileName encodeString:NSUTF8StringEncoding]];
    NSString *folderSameName = [NSString stringWithFormat:@"%@/",[fileName encodeString:NSUTF8StringEncoding]];
    NSPredicate *predicateSameFolderName = [NSPredicate predicateWithFormat:@"fileName == %@", folderSameName];

    NSArray *filesSameFileName = [self.currentDirectoryArray filteredArrayUsingPredicate:predicateSameFileName];
    NSArray *filesSameFolderName = [self.currentDirectoryArray filteredArrayUsingPredicate:predicateSameFolderName];


    if ((filesSameFileName !=nil && filesSameFileName.count > 0) || (filesSameFolderName != nil && filesSameFolderName.count >0)) {
        sameName = YES;
    }

    
    return sameName;
}

- (BOOL) isValidTitleName:(NSString *)fileName {
    
    BOOL valid = NO;
    if (!([fileName length] == 0)) {
        if (![FileNameUtils isForbiddenCharactersInFileName:fileName withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport]]) {
            
            if (![self existFileWithSameName:fileName]) {
                valid = YES;
            } else {
                DLog(@"Exist a file with the same name");
                
                [self showAlertView:[NSString stringWithFormat:@"%@ %@",fileName, NSLocalizedString(@"error_text_file_exist", nil)]];
            }
        } else {
            [self showAlertView:NSLocalizedString(@"forbidden_characters_from_server", nil)];
        }
    } else {
         [self showAlertView:NSLocalizedString(@"error_file_name_empty", nil)];
    }
    
    return valid;
}


#pragma mark - store file

- (NSString *) storeFileWithTitle:(NSString *)fileName andBody:(NSString *)bodyTextFile {
    DLog(@"New File with name: %@", fileName);
    
    NSString *tempPath = [UtilsFileSystem temporalFileNameByName:fileName];
    NSData* fileData = [bodyTextFile dataUsingEncoding:NSUTF8StringEncoding];
    [UtilsFileSystem createFileOnTheFileSystemByPath:tempPath andData:fileData];
    
    return tempPath;
}



#pragma mark - Upload text file

- (void) sendTextFileToUploadsByTempLocalPath:(NSString *)tempLocalPath andFileName:(NSString *)fileName {
   
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSString *fullRemotePath = @"";
    
    if (self.isModeEditing) {
        fullRemotePath = [NSString stringWithFormat:@"%@",[UtilsUrls getFullRemoteServerParentPathByFile:self.currentFileDto andUser:app.activeUser]];
    } else {
        fullRemotePath = [NSString stringWithFormat:@"%@",[UtilsUrls getFullRemoteServerFilePathByFile:self.currentFileDto andUser:app.activeUser]];
    }
    
    long long fileLength = [[[[NSFileManager defaultManager] attributesOfItemAtPath:tempLocalPath error:nil] valueForKey:NSFileSize] unsignedLongLongValue];
    
    if (![UtilsUrls isFileUploadingWithPath:fullRemotePath andUser:app.activeUser]) {
        
        UploadsOfflineDto *upload = [UploadsOfflineDto new];
        
        upload.originPath = tempLocalPath;
        upload.destinyFolder = fullRemotePath;
        upload.uploadFileName = fileName;
        upload.kindOfError = notAnError;
        upload.estimateLength = (long)fileLength;
        upload.userId = self.currentFileDto.userId;
        upload.isLastUploadFileOfThisArray = YES;
        upload.chunksLength = k_lenght_chunk;
        upload.isNotNecessaryCheckIfExist = NO;
        upload.isInternalUpload = NO;
        upload.taskIdentifier = 0;
        
        if (self.isModeEditing) {
             upload.status = generatedByDocumentProvider;
            [ManageFilesDB setFileIsDownloadState:self.currentFileDto.idFile andState:overwriting];
            [ManageUploadsDB insertUpload:upload];
            [app launchUploadsOfflineFromDocumentProvider];
        } else {
            upload.status = pendingToBeCheck;
            [ManageUploadsDB insertUpload:upload];
            [app initUploadsOffline];
        }
    }

}

- (void) showAlertView:(NSString*)string{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
}


@end
