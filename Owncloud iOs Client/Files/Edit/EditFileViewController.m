//
//  EditFileViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 04/05/16.
//
//

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
    //self.bodyTextView.text = NSLocalizedString(@"body_text_file_placeholder", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
}


#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"title_view_edit_file", nil);
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
   
    NSString *fileName = [NSString stringWithFormat:@"%@.txt", self.titleTextField.text];
    NSString *bodyTextFile = self.bodyTextView.text;
    
    if ([self isValidTitleName:fileName]) {
        [self storeFileWithTitle:fileName andBody:bodyTextFile];
        [self sendTextFileToUploads:fileName];
        [self dismissViewControllerAnimated:true completion:nil];
    }
    
}

- (void) closeViewController {
    
    [self dismissViewControllerAnimated:true completion:nil];
}



#pragma mark - store file

- (void) storeFileWithTitle:(NSString *)fileName andBody:(NSString *)bodyTextFile {
    DLog(@"New File with name: %@", fileName);

    NSString *tempPath = [NSString stringWithFormat:@"%@%@", [UtilsUrls getTempFolderForUploadFiles], fileName];
    NSData* fileData = [bodyTextFile dataUsingEncoding:NSUTF8StringEncoding];
    [self createFileOnTheFileSystem:tempPath withData:fileData];
    
}

- (void) createFileOnTheFileSystem:(NSString *)tempPath withData:(NSData *)fileData {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]){
        [[NSFileManager defaultManager] createFileAtPath:tempPath
                                                contents:fileData
                                              attributes:nil];
    }
    
}


#pragma mark - Check title name

- (BOOL) existSameName:(NSString*)fileName {
    
    BOOL sameName = NO;
    
    self.currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:self.currentFileDto.idFile];

    NSPredicate *predicateSameName = [NSPredicate predicateWithFormat:@"fileName == %@", fileName];
    NSArray *filesSameName = [self.currentDirectoryArray filteredArrayUsingPredicate:predicateSameName];

    if (filesSameName !=nil && filesSameName.count > 0) {
        sameName = YES;
    }
    
    return sameName;
}

- (BOOL) isValidTitleName:(NSString *)fileName {
    
    BOOL valid = NO;
    if (![fileName isEqualToString:@".txt"]) {
        if (![FileNameUtils isForbiddenCharactersInFileName:fileName withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport]]) {
            
            //Check if exist a file with the same name
            if (![self existSameName:fileName]) {
                valid = YES;
                
            } else {
                DLog(@"Exist a file with the same name");
                [self showAlertView:NSLocalizedString(@"text_file_exist", nil)];
            }
        } else {
            [self showAlertView:NSLocalizedString(@"forbidden_characters_from_server", nil)];
        }
    } else {
         [self showAlertView:NSLocalizedString(@"title_text_file_empty", nil)];
    }
    
    return valid;
}



#pragma mark - Upload text file

- (void) sendTextFileToUploads:(NSString *)localPath {

    
}

- (void) showAlertView:(NSString*)string{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

-(void) errorLogin {

}

#pragma mark - Server connect methods

/*
 * Method called when receive a fail from server side
 * @errorCodeFromServer -> WebDav Server Error of NSURLResponse
 * @error -> NSError of NSURLConnection
 */

- (void)manageServerErrors: (NSInteger)errorCodeFromServer and:(NSError *)error {
    
//    [self stopPullRefresh];
//    [self endLoading];
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [_manageNetworkErrors manageErrorHttp:errorCodeFromServer andErrorConnection:error andUser:app.activeUser];
}

/*
 * Method that quit the loading screen and unblock the view
 */
- (void)endLoading {
    
//    if (!_isLoadingForNavigate) {
//        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//        //Check if the loading should be visible
//        if (app.isLoadingVisible==NO) {
//            // [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
//            [_HUD removeFromSuperview];
//            self.view.userInteractionEnabled = YES;
//            self.navigationController.navigationBar.userInteractionEnabled = YES;
//            self.tabBarController.tabBar.userInteractionEnabled = YES;
//            [self.view.window setUserInteractionEnabled:YES];
//        }
//        
//        //Check if the app is wainting to show the upload from other app view
//        if (app.isFileFromOtherAppWaitting && app.isPasscodeVisible == NO) {
//            [app performSelector:@selector(presentUploadFromOtherApp) withObject:nil afterDelay:0.3];
//        }
//        
//        if (!_rename.renameAlertView.isVisible) {
//            _rename = nil;
//        }
//    }
}

@end
