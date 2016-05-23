//
//  EditFileViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 04/05/16.
//
//

/*
 Copyright (C) 2016, ownCloud, Inc.
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
#import "Customization.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "UtilsUrls.h"
#import "NSString+Encoding.h"
#import "ManageNetworkErrors.h"
#import "UploadsOfflineDto.h"
#import "ManageUploadsDB.h"
#import "UtilsFileSystem.h"


#define k_default_extension @"txt"

@interface EditFileViewController ()

@end

@implementation EditFileViewController

- (id)initWithFileDto:(FileDto *)fileDto {
   
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.currentFileDto = fileDto;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.titleTextField.placeholder = NSLocalizedString(@"title_text_file_placeholder", nil);
    self.titleTextField.text = [NSString stringWithFormat:@"%@.%@",NSLocalizedString(@"default_text_file_title", nil),k_default_extension];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated{
    [self.bodyTextView becomeFirstResponder];
    [super viewWillAppear:animated];
    [self setStyleView];
}


#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"title_view_new_text_file", nil);
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
   
    NSString *fileName = [self.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ];
    NSString *bodyTextFile = self.bodyTextView.text;
    
    if ([self isValidTitleName:fileName]) {
        
        NSString *tempLocalPath = [self storeFileWithTitle:fileName andBody:bodyTextFile];
        if (tempLocalPath) {
            [self sendTextFileToUploadsByTempLocalPath:tempLocalPath andFileName:fileName];
        }
        [self dismissViewControllerAnimated:true completion:nil];
    }
    
}

- (void) closeViewController {
    
    [self dismissViewControllerAnimated:true completion:nil];
}


#pragma mark - Check title name

- (BOOL) existFileWithSameName:(NSString*)fileName {
    
    BOOL sameName = NO;
    
    self.currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:self.currentFileDto.idFile];

    NSPredicate *predicateSameName = [NSPredicate predicateWithFormat:@"fileName == %@", [fileName encodeString:NSUTF8StringEncoding]];
    NSArray *filesSameName = [self.currentDirectoryArray filteredArrayUsingPredicate:predicateSameName];

    if (filesSameName !=nil && filesSameName.count > 0) {
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
                [self showAlertView:NSLocalizedString(@"error_text_file_exist", nil)];
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

    NSString *fullRemotePath = [NSString stringWithFormat:@"%@",[UtilsUrls getFullRemoteServerFilePathByFile:self.currentFileDto andUser:app.activeUser]];
    
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
        upload.status = pendingToBeCheck;
        upload.chunksLength = k_lenght_chunk;
        upload.isNotNecessaryCheckIfExist = NO;
        upload.isInternalUpload = NO;
        upload.taskIdentifier = 0;
        
        [ManageUploadsDB insertUpload:upload];
        [app relaunchUploadsFailedForced];
    }

}

- (void) showAlertView:(NSString*)string{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
}


@end
