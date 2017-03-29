//
//  UploadFromOtherAppViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 29/10/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UploadFromOtherAppViewController.h"

#import "UserDto.h"
#import "SelectFolderViewController.h"
#import "constants.h"
#import "AppDelegate.h"
#import "FilesViewController.h"
#import "MBProgressHUD.h"
#import "UIColor+Constants.h"
#import "FileNameUtils.h"
#import "Customization.h"
#import "OverwriteFileOptions.h"
#import "DeleteFile.h"
#import "UtilsDtos.h"
#import "ManageFilesDB.h"
#import "OCErrorMsg.h"
#import "FileNameUtils.h"
#import "UtilsNetworkRequest.h"
#import "EditAccountViewController.h"
#import "Download.h"
#import "FilePreviewViewController.h"
#import "NSString+Encoding.h"
#import "UploadUtils.h"
#import "OCNavigationController.h"
#import "UtilsUrls.h"
#import "ManageUsersDB.h"
#import "ManageThumbnails.h"

#define kOFFSET_FOR_KEYBOARD_iPhone5 160.0
#define kOFFSET_FOR_KEYBOARD_iPhone 200.0
#define kOFFSET_FOR_KEYBOARD_iPad 147.0
#define kOFFSET_FOR_KEYBOARD_iPhone5_Landscape 160.0
#define kOFFSET_FOR_KEYBOARD_iPhone_Landscape 160.0

@interface UploadFromOtherAppViewController ()

@end

@implementation UploadFromOtherAppViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        

    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _utilsNetworkRequest = [UtilsNetworkRequest new];
    _utilsNetworkRequest.delegate = self;

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if(self.alertFileExist) {
        [self.alertFileExist dismissWithClickedButtonIndex:0 animated:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
	[self.navigationItem setLeftBarButtonItem:cancelButton];
    
    UIBarButtonItem *sendToButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"other_apps_send_to", nil) style:UIBarButtonItemStyleDone target:self action:@selector(sendTo)];
    
	[self.navigationItem setRightBarButtonItem:sendToButton];
    
    self.navigationItem.title = NSLocalizedString(@"other_apps_title", nil);
 
    //Keyboard hidding
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];
    
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:
     UIKeyboardWillHideNotification object:nil];
    
    _oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                            action:@selector(didTapAnywhere:)];
    _oneTap.delegate=self;
    
    _userName = app.activeUser.username;
    
    _serverName = app.activeUser.url;
    
    _remoteFolder = [UtilsUrls getFullRemoteServerPathWithWebDav:app.activeUser];
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    _folderName=appName;
    
    //Post a notification to inform to the PreviewFileViewController class
    //FileDto *filePreview;
    //[[NSNotificationCenter defaultCenter] postNotificationName:PreviewFileNotification object:filePreview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    DLog(@"UploadFromOtherApp shouldAutorotate");
   /* if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }else{
        return YES;
    }*/
    
    return YES;
    
}

//Only for ios6
- (NSUInteger)supportedInterfaceOrientations
{
    if (IS_IPHONE) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }else{
        return UIInterfaceOrientationMaskAll;
    }
    
}

//Only for ios 6
- (BOOL)shouldAutorotate {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    //We set the current name to not lost it on reload
    _auxFileName = _nameFileTextField.text;
    [_tableView reloadData];
    
    if(_overWritteOption) {
        if(IS_IPHONE) {
            [_overWritteOption.renameAlertView dismissWithClickedButtonIndex:0 animated:NO];
        }
        [_overWritteOption.overwriteOptionsActionSheet dismissWithClickedButtonIndex:0 animated:NO];
    }
}


- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}
#pragma mark Util Actions

/*
 * Method that return a NSUInteger with the KB sizse of the file
 */
- (NSUInteger)getFileSizeOfFile:(NSString*)file{
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
    NSNumber * size = [attributes objectForKey: NSFileSize];
    NSUInteger length = [size integerValue];
    
    DLog(@"Size is: %lu", (unsigned long)length);
    
    return length;    
}

- (NSString*)getFileName:(NSString*)string{
    
    NSArray *splitedUrl = [string componentsSeparatedByString:@"/"];
    // int cont = [splitedUrl count];
    NSString *fileName = [NSString stringWithFormat:@"%@",[splitedUrl objectAtIndex:([splitedUrl count]-1)]];
    
    return fileName;    
}

#pragma mark HUD actions
-(void)initLoading {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud bringSubviewToFront:self.view];
    
    hud.labelText = NSLocalizedString(@"loading", nil);
    hud.dimBackground = YES;
    
    self.view.userInteractionEnabled = NO;
    
}

- (void)endLoading {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
    
}


#pragma mark Action Buttons

- (void)cancel{
    
    //Deleta file
    [[NSFileManager defaultManager] removeItemAtPath:_filePath error: nil];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isSharedToOwncloudPresent=NO;
    
    //Close this view
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
    
}

- (void) sendTo{
    
    NSString *name = _nameFileTextField.text;
    
    //Check the name of the file for it has forbiden characters
    
    if(![FileNameUtils isForbiddenCharactersInFileName:name withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport]]) {
        
        name = [name encodeString:NSUTF8StringEncoding];
        
        NSString *remotePath = [NSString stringWithFormat:@"%@%@",_remoteFolder, name];
        
        [self initLoading];
        
        DLog(@"remote path: %@", remotePath);
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        //Check if the item already exists in the path
        [_utilsNetworkRequest checkIfTheFileExistsWithThisPath:remotePath andUser:app.activeUser];
        
    
    } else {
       
        DLog(@"The file name have problematic characters");
        
        NSString *msg = nil;
        msg = NSLocalizedString(@"forbidden_characters_from_server", nil);
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
/*
    //Post a notification to inform to the PreviewFileViewController class
    NSString *path= [NSString stringWithFormat:@"%@%@", _remoteFolder,name];
    [[NSNotificationCenter defaultCenter] postNotificationName:PreviewFileNotification object:path];*/
    
}

#pragma mark - OCWebDav Methods

- (void) showErrorConnectionPopUp{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self endLoading];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil)
                                                        message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    });

}

#pragma mark - UtilsNetworkRequestDelegate
- (void)theFileIsInThePathResponse:(NSInteger) response {
    
    [self endLoading];
    
    switch (response) {
        case isInThePath:
        {
            if (IS_IPHONE && !IS_PORTRAIT) {
                
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                                   message:NSLocalizedString(@"not_show_potrait", nil)
                                                                  delegate:nil
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
                [alertView show];
            } else {
                FileDto *file = [[FileDto alloc] init];
                file.fileName = self.nameFileTextField.text;
                file.isDirectory = NO;
                
                _overWritteOption = [[OverwriteFileOptions alloc] init];
                _overWritteOption.viewToShow = self.view;
                _overWritteOption.delegate = self;
                _overWritteOption.fileDto = file;
                [_overWritteOption showOverWriteOptionActionSheet];
            }
        }
            break;
        case isNotInThePath:
            [self saveTheFileOnOwncloud:NO];
            break;
        case credentialsError:
            [self errorLoginCheckingThePath];
            break;
        case serverConnectionError:
            [self saveTheFileOnOwncloud:NO];
            break;
        default:
            break;
    }
}

- (void) errorLoginCheckingThePath{
    
    [self endLoading];
    
    [self showEditAccountViewController];
    
}

- (void) otherErrorCheckingThePath{
    
    [self endLoading];
    
}

#pragma mark - UITableView datasource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int n;
    
    if (section==0) {
        n=0;
    }else{
        n=1;
    }
       
    
    return n;
}


// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{   
    static NSString *CellIdentifier = @"UploadFromOtherAppIdentifier";
    
    UITableViewCell *cell = nil;

    // if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];        
  //  }
    
    
    UIFont *cellFont = [UIFont systemFontOfSize:17.0];
    UIFont *cellBoldFont = [UIFont boldSystemFontOfSize:17.0];
    cell.textLabel.font=cellFont;
    
    if (indexPath.section==1) {
        
        cell.selectionStyle=UITableViewCellSelectionStyleNone;        
        
        NSString *accountString=[NSString stringWithFormat:@"%@@%@", _userName, _serverName];
        //If SAML enabled replacing the escapes 
        if (k_is_sso_active) {
            accountString=[accountString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        cell.textLabel.text=accountString;
        cell.textLabel.font=cellBoldFont;       
        
               
        
    }else if (indexPath.section==2) {
        
        cell.selectionStyle=UITableViewCellSelectionStyleBlue;
        NSString *fName= [_folderName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        cell.textLabel.text=fName;
        cell.textLabel.font=cellBoldFont;
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        
    }else if (indexPath.section==3){
              
        
        //UITextField
        CGRect textFieldFrame;
        //Only for iOS 7
        textFieldFrame = CGRectMake(10,10,_tableView.frame.size.width-15,20);
        
        _nameFileTextField = [[UITextField alloc]initWithFrame:textFieldFrame];
        
        _nameFileTextField.delegate = self;
        [_nameFileTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
        _nameFileTextField.borderStyle= UITextBorderStyleNone;
        [_nameFileTextField setReturnKeyType:UIReturnKeyDone];
        [_nameFileTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [_nameFileTextField setPlaceholder:NSLocalizedString(@"other_apps_file_name", nil)];
        [_nameFileTextField setFont:cellBoldFont];
        [_nameFileTextField setTextAlignment:NSTextAlignmentLeft];
        
        _nameFileTextField.font = [UIFont boldSystemFontOfSize:16.0];
        [_nameFileTextField setTextColor:[UIColor blackColor]];
        if(_auxFileName) {
            _nameFileTextField.text = _auxFileName;
        } else {
            NSString *fileName;
            fileName=[self getFileName:_filePath];
            [_nameFileTextField setText:[fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        
        [cell.contentView addSubview:_nameFileTextField];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    
    return cell;
}

- (void)markFileName{
    
    //Check if the filename have extension and is not a directory
    if(([_nameFileTextField.text rangeOfString:@"."].location != NSNotFound)) {
        [FileNameUtils markFileNameOnAlertView:_nameFileTextField];
    }
}

#pragma mark - UITableView delegate

// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section==2) {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        //We set the current name to not lost it on reload
        _auxFileName = _nameFileTextField.text;
        
        SelectFolderViewController *sf = [[SelectFolderViewController alloc] initWithNibName:@"SelectFolderViewController" onFolder:[ManageFilesDB getRootFileDtoByUser:app.activeUser]];
        sf.toolBarLabelTxt = @"";
        
        SelectFolderNavigation *navigation = [[SelectFolderNavigation alloc]initWithRootViewController:sf];
        sf.parent=navigation;
        
        //Root Remote Folder.
        sf.currentRemoteFolder=_remoteFolder;
        
        //We get the current folder to create the local tree
        NSString *localRootUrlString = [NSString stringWithFormat:@"%@%ld/", [UtilsUrls getOwnCloudFilePath],(long)app.activeUser.idUser];
        
        sf.currentLocalFolder = localRootUrlString;
        
        navigation.delegate=self;
        
        if (IS_IPHONE)
        {
            [self presentViewController:navigation animated:YES completion:nil];
            
        } else {
            navigation.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            navigation.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navigation animated:YES completion:nil];
            
        }
    }    
    
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    //UIView have:
        // UIImageView of type of file
        // UILabel of filename
        // UILabel of size
    
    UIView *fileView;
    
    
    if (section==0) {
        //UIView
        CGRect viewFrame = CGRectMake(0, 0, _tableView.frame.size.width, 168);
        fileView = [[UIView alloc]initWithFrame:viewFrame];
        
        //FileName
        NSString *fileName = [self getFileName:_filePath];
        
        //File Size
        NSUInteger fileSize = [self getFileSizeOfFile:_filePath];
        
        NSString *fileSizeString;
        
        
        //Bytes
        if (fileSize < 1024) {
            fileSizeString = [NSString stringWithFormat:@"%lu Bytes", (unsigned long)fileSize];
        }else if ((fileSize/1024)<1048576){
            //KB
            fileSizeString = [NSString stringWithFormat:@"%lu KB", (unsigned long)(fileSize/1024)];
        }else{
            //MB
            fileSizeString = [NSString stringWithFormat:@"%lu MB", (unsigned long)((fileSize/1024)/1024)];
        }
        
        //Image name by extension
        NSString *imageName= [FileNameUtils getTheNameOfTheImagePreviewOfFileName:fileName];
        
        CGRect imageFrame;
        if (IS_IPHONE) {
            imageFrame = CGRectMake(10, 20, 128, 128);
        } else{
            imageFrame = CGRectMake(25, 20, 128, 128);
        }
        
       
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:imageFrame];
        [imageView setImage:[UIImage imageNamed:imageName]];
        
        
        //Label of fileName
        CGRect nameFrame = CGRectMake(148, 40, (_tableView.frame.size.width - 158), 16);
        UILabel *nameLabel = [[UILabel alloc]initWithFrame:nameFrame];
        
        nameLabel.backgroundColor=[UIColor clearColor];
        nameLabel.textColor = [UIColor blackColor];
        nameLabel.textAlignment = NSTextAlignmentLeft;
        [nameLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
        [nameLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];        
        [nameLabel setClipsToBounds:YES];
        
       nameLabel.text=[fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
       // nameLabel.text=fileName;
        
        //Label of size
        CGRect sizeFrame = CGRectMake(148, 65, (_tableView.frame.size.width - 158), 16);
        UILabel *sizeLabel = [[UILabel alloc]initWithFrame:sizeFrame];
        
        sizeLabel.backgroundColor=[UIColor clearColor];
        sizeLabel.textColor = [UIColor blackColor];
        sizeLabel.textAlignment = NSTextAlignmentLeft;
        [sizeLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
        [sizeLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [sizeLabel setClipsToBounds:YES];        
        sizeLabel.text=fileSizeString;
        
        
        //Add imageView to uiView
        [fileView addSubview:imageView];
        [fileView addSubview:nameLabel];
        [fileView addSubview:sizeLabel];
    } else {
        
        fileView=nil;
    }
    
    return fileView;
    
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    NSString *title;
    
    if (section==0) {
        title=@"";
        
    }else if (section==1){
        title=NSLocalizedString(@"other_apps_account", nil);
    }else if (section==2){
        title=NSLocalizedString(@"other_apps_folder", nil);
    }else if (section==3){
        title=NSLocalizedString(@"other_apps_file_name",nil);
    }
    
    return title;    
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    CGFloat height;
    
    if (section==0) {
        height=168.0;
    }else{
        height=20.0;
        
    }
    
    return height;
    
}

#pragma mark Select Folder Navigation Delegate Methods
- (void)folderSelected:(NSString*)folder{
    DLog(@"Change Folder");
    //TODO. Change current Remote Folder
    _remoteFolder=folder;
    
    NSArray *splitedUrl = [folder componentsSeparatedByString:@"/"];
    // int cont = [splitedUrl count];
    NSString *folderName = [NSString stringWithFormat:@"/%@",[splitedUrl objectAtIndex:([splitedUrl count]-2)]];
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    DLog(@"Folder is:%@", folderName);
    if ([folderName isEqualToString:@"/webdav.php"] || [folderName isEqualToString:@"/webdav"]) {
        folderName=appName;
    }
    _folderName=folderName;
    
    [self.tableView reloadData];
    
}
- (void)cancelFolderSelected{
    
    //Nothing
    DLog(@"Cancel folder");
}


#pragma mark - UIGestures
-(void) keyboardWillShow:(NSNotification *) note {
     [_oneTap setCancelsTouchesInView:YES];
    [self.tableView addGestureRecognizer:_oneTap];
    
}

-(void) keyboardWillHide:(NSNotification *) note
{
    [self.tableView removeGestureRecognizer:_oneTap];
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer {
    DLog(@"Did tap anywhere");
    
    [_nameFileTextField resignFirstResponder];   
    
}

#pragma mark - UIGestureDelegate methods
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view.superview isKindOfClass:[UITextField class]]){
        return FALSE;
        
    }
    return TRUE;
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

// Animate the entire view up or down, to prevent the keyboard from covering the author field.
- (void)setViewMovedUp:(BOOL)movedUp
{
    DLog(@"setViewMoveUp");
    
  /*  NSIndexPath *scrollIndexPath = nil;
    
    if (movedUp==YES) {
        scrollIndexPath = [NSIndexPath indexPathForRow:1 inSection:3];
    }else{
        scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    [_tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];*/
    
     [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
	
	// Make changes to the view's frame inside the animation block. They will be animated instead
	// of taking place immediately.
	
	CGRect rect = _tableView.frame;    
    //Depend of the device the offeset for keyboard change
    CGFloat key_offset;   
    
    if (IS_IPHONE) {
        if ([UIScreen mainScreen].bounds.size.height <=480.0) {            
            if (IS_PORTRAIT) {
                key_offset=kOFFSET_FOR_KEYBOARD_iPhone;
            }else{
                key_offset=kOFFSET_FOR_KEYBOARD_iPhone_Landscape;
            }            
            
        }else{
            if (IS_PORTRAIT) {
                key_offset=kOFFSET_FOR_KEYBOARD_iPhone5;
            }else{
                key_offset=kOFFSET_FOR_KEYBOARD_iPhone5_Landscape;
            }
        }
    }else{
        key_offset=kOFFSET_FOR_KEYBOARD_iPad;
    }
    
	
	if (movedUp) {
		// If moving up, not only decrease the origin but increase the height so the view
		// covers the entire screen behind the keyboard.
		rect.origin.y -= key_offset;
		// rect.size.height += kOFFSET_FOR_KEYBOARD;
	} else {
		// If moving down, not only increase the origin but decrease the height.
		rect.origin.y += key_offset;
		// rect.size.height -= kOFFSET_FOR_KEYBOARD;
	}
	
	//self.view.frame = rect;
	_tableView.frame=rect;
	[UIView commitAnimations];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    UIInterfaceOrientation currentOrientation;
    currentOrientation=[[UIApplication sharedApplication] statusBarOrientation];
    BOOL isPotrait = UIDeviceOrientationIsPortrait(currentOrientation);
    
    
    if (textField==_nameFileTextField) {
        if (IS_IPHONE) {
            [self setViewMovedUp:YES];
            [self markFileName];
        }else{
            if (isPotrait==NO) {
                DLog(@"landscape");
                [self setViewMovedUp:YES];
            }
        }
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
        
    UIInterfaceOrientation currentOrientation;
    currentOrientation=[[UIApplication sharedApplication] statusBarOrientation];
    BOOL isPotrait = UIDeviceOrientationIsPortrait(currentOrientation);
    
    
    if (textField==_nameFileTextField) {
        if (IS_IPHONE) {
            [self setViewMovedUp:NO];
        }else{
            //ipad
            if (isPotrait==NO) {
                DLog(@"landscape");
                [self setViewMovedUp:NO];
            }
        }
    }

}

- (void)quitSendToButton{
    
    [self.navigationItem setRightBarButtonItem:nil];
    
}

- (void)putSendToButton{
    
    UIBarButtonItem *sendToButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"other_apps_send_to", nil) style:UIBarButtonItemStyleDone target:self action:@selector(sendTo)];
    
	[self.navigationItem setRightBarButtonItem:sendToButton];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField{
    
    if (textField==_nameFileTextField) {
        [self quitSendToButton];
    }
    
    return YES;
    
}
// Asks the delegate if the text field should process the pressing of the return button.
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{   
    
    if (textField == _nameFileTextField) {
        [textField resignFirstResponder];
    }
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField==_nameFileTextField) {
        
        NSString *stringNow = [textField.text stringByReplacingCharactersInRange:range withString:string];       
        
        //Active button of folderview only when the textfield has something.
        NSString *rawString = stringNow;
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
        
        if ([trimmed length] == 0) {
            // Text was empty or only whitespace.
            [self quitSendToButton];
        }else {
            [self putSendToButton];
        }
        
        //Button save disable when the textfield is empty
        if ([stringNow isEqualToString:@""]) {
            [self quitSendToButton];
        }
    }
    
    return YES;
    
}


/*
 * This method show the edit account view.
 */
- (void)showEditAccountViewController{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:app.activeUser andLoginMode:LoginModeExpire];
    
    if (IS_IPHONE)
    {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else {
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentViewController:navController animated:YES completion:nil];
    }
}


- (void)saveTheFileOnOwncloud:(BOOL) isNotNecessaryCheckIfExist {
    //TODO Upload file
    NSString *name = _nameFileTextField.text;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Call this method to manager the uploads with this new upload.
    
    DLog(@"New name: %@", name);
    DLog(@"self.filePath: %@", self.filePath);
    
    
    [app itemToUploadFromOtherAppWithName:name andPathName:self.filePath andRemoteFolder:_remoteFolder andIsNotNeedCheck:isNotNecessaryCheckIfExist];
    
    //Flag inidicate to sharedtoowncloud view is dissmiss
    app.isSharedToOwncloudPresent=NO;
    
    //Close this view
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate
- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex {
    // cancel
    if( buttonIndex == 1 ){
        //Save file
        [self saveTheFileOnOwncloud:NO];
    }else if (buttonIndex == 0) {
        //Cancel
        
    }else {
        //Nothing
    }
}


#pragma mark - OverwriteFileOptionsDelegate

- (void) setNewNameToSaveFile:(NSString *)name {
    DLog(@"setNewNameToSaveFile: %@", name);
    
    _nameFileTextField.text = name;
    _auxFileName = name;
    [self.tableView reloadData];
    //To this way the keyboard is hidden before the uploadFromOtherApp view will be dismissed
    [self performSelector:@selector(sendTo) withObject:nil afterDelay:0.2];
}

- (void) overWriteFile {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //A overwrite process is in progress
    app.isOverwriteProcess = YES;
    
    //Get the name in the correct encoding
    NSString *name=[_nameFileTextField.text encodeString:NSUTF8StringEncoding];
    
    //The _remoteFolder: https://domain/(subfoldersServer)/k_url_webdav_server/(subfoldersDB)/
    //The nameFileTextField: FileType.pdf
    //The folder Name: (subfoldersDB)/
    
    NSString *folderName = [UtilsUrls getFilePathOnDBByFullPath:_remoteFolder andUser:app.activeUser];
    
    //Obtain the file that the user wants overwrite
    FileDto *file = nil;
    file = [ManageFilesDB getFileDtoByFileName:name andFilePath:folderName andUser:app.activeUser];
    
    //Check if this file is being updated and cancel it
    Download *downloadFile;
    NSArray *downloadsArrayCopy = [NSArray arrayWithArray:[app.downloadManager getDownloads]];
    
    for (downloadFile in downloadsArrayCopy) {
        if (([downloadFile.fileDto.fileName isEqualToString: file.fileName]) && ([downloadFile.fileDto.filePath isEqualToString: file.filePath])) {
            [downloadFile cancelDownload];
        }
    }
    downloadsArrayCopy=nil;
    
    if (file.isDownload == downloaded) {
        //Set this file as an overwritten state
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:overwriting];
        [UploadUtils updateOverwritenFile:file FromPath:_filePath];
        [[ManageThumbnails sharedManager] removeStoredThumbnailForFile:file];
    }
    
    [self saveTheFileOnOwncloud:YES];
    
    [app.presentFilesViewController reloadTableFromDataBase];
}


@end
