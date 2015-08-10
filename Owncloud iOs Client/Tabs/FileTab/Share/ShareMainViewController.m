//
//  ShareMainViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/8/15.
//

/*
 Copyright (C) 2015, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareMainViewController.h"
#import "ManageFilesDB.h"
#import "UtilsUrls.h"
#import "UserDto.h"
#import "OCSharedDto.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "FileNameUtils.h"

//tools
#define standardDelay 0.2

//Cells and Sections
#define shareFileCellIdentifier @"ShareFileIdentifier"
#define shareFileCellNib @"ShareFileCell"
#define shareLinkOptionIdentifer @"ShareLinkOptionIdentifier"
#define shareLinkOptionNib @"ShareLinkOptionCell"
#define shareLinkHeaderIdentifier @"ShareLinkHeaderIdentifier"
#define shareLinkHeaderNib @"ShareLinkHeaderCell"
#define shareLinkButtonIdentifier @"ShareLinkButtonIdentifier"
#define shareLinkButtonNib @"ShareLinkButtonCell"
#define heighOfFileDetailrow 120.0
#define heightOfShareLinkOptionRow 55.0
#define heightOfShareLinkHeader 40.0
#define shareTableViewSectionsNumber  2

//Nº of Rows
#define optionsShownWithShareLinkEnable 3
#define optionsShownWithShareLinkDisable 0

@interface ShareMainViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic) NSInteger optionsShownWithShareLink;
@property (nonatomic) BOOL isShareLinkEnabled;
@property (nonatomic, strong) NSString* sharedToken;
@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;


@end


@implementation ShareMainViewController


- (id) initWithFileDto:(FileDto *)fileDto {
    
    if ((self = [super initWithNibName:@"ShareViewController" bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.optionsShownWithShareLink = 0;
        self.isShareLinkEnabled = false;
        
    }
    
    return self;
}

- (void) viewDidLoad{
    [super viewDidLoad];
    
    
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self setStyleView];
    [self updateInterfaceWithShareLinkStatus];
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    
}

#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = @"Share";
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(didSelectCloseView)];
    self.navigationItem.leftBarButtonItem = barButton;
    
}

- (void) reloadView {
    
    if (self.isShareLinkEnabled == true){
        self.optionsShownWithShareLink = optionsShownWithShareLinkEnable;
    }else{
        self.optionsShownWithShareLink = optionsShownWithShareLinkDisable;
    }
    
    [self.shareTableView reloadData];
}

#pragma mark - Action Methods

- (void) updateInterfaceWithShareLinkStatus {
    
    if (self.sharedItem.sharedFileSource > 0) {
        self.isShareLinkEnabled = true;
    }else{
        self.isShareLinkEnabled = false;
    }
    
    [self reloadView];
    
}

- (void) didSelectCloseView {
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) sharedLinkSwithValueChanged: (UISwitch*)sender {
    
    self.isShareLinkEnabled = sender.on;
    
    if (self.isShareLinkEnabled == true) {
        [self getShareLinkView];
    } else{
        [self unShareByLink];
    }
}

- (void) getShareLinkView {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    if (IS_IPHONE) {
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
    }else{
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
        self.sharedFileOrFolder.parentView = self.view;
    }
    
    if (self.sharedItem.sharedFileSource > 0){
        self.sharedFileOrFolder.file = self.sharedItem;
        [self.sharedFileOrFolder clickOnShareLinkFromFileDto:true];
    }else{
        [self.sharedFileOrFolder showShareActionSheetForFile:self.sharedItem];
    }
    
    
}

- (void) unShareByLink {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    OCSharedDto *ocShare = [self.sharedFileOrFolder getTheOCShareByFileDto:self.sharedItem];
    
    if (ocShare != nil) {
        [self.sharedFileOrFolder unshareTheFile:ocShare];
    }
    
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return shareTableViewSectionsNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else{
        return self.optionsShownWithShareLink;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (indexPath.section == 0) {
        
        ShareFileCell* shareFileCell = (ShareFileCell*)[tableView dequeueReusableCellWithIdentifier:shareFileCellIdentifier];
        
        if (shareFileCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareFileCellNib owner:self options:nil];
            shareFileCell = (ShareFileCell *)[topLevelObjects objectAtIndex:0];
        }
        
        if (self.sharedItem.isDirectory == true) {
            shareFileCell.fileImage.image = [UIImage imageNamed:@"folder_icon"];
            shareFileCell.fileSize.text = @"";
        }else{
            shareFileCell.fileImage.image = [UIImage imageNamed:[FileNameUtils getTheNameOfTheImagePreviewOfFileName:[self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            shareFileCell.fileSize.text = [NSByteCountFormatter stringFromByteCount:[NSNumber numberWithLong:self.sharedItem.size].longLongValue countStyle:NSByteCountFormatterCountStyleMemory];
        }
        
        shareFileCell.fileName.text = [self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        cell = shareFileCell;
        
    } else {
        
        if (indexPath.row == 2) {
            
            ShareLinkButtonCell *shareLinkButtonCell = [tableView dequeueReusableCellWithIdentifier:shareLinkButtonIdentifier];
            
            if (shareLinkButtonCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkButtonNib owner:self options:nil];
                shareLinkButtonCell = (ShareLinkButtonCell *)[topLevelObjects objectAtIndex:0];
            }
            
            shareLinkButtonCell.titleButton.text = @"Get Share Link";
            
            cell = shareLinkButtonCell;
            
            
        } else {
            
            ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];
            
            if (shareLinkOptionCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
                shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0:
                    shareLinkOptionCell.optionName.text = @"Set expiration time";
                    shareLinkOptionCell.detailTextLabel.text = @"empty";
                    [shareLinkOptionCell.optionSwith setOn:false animated:true];
                    break;
                case 1:
                    shareLinkOptionCell.optionName.text = @"Password protect";
                    shareLinkOptionCell.detailTextLabel.text = @"empty";
                    [shareLinkOptionCell.optionSwith setOn:false animated:true];
                    break;
                    
                default:
                    //Not expected
                    DLog(@"Not expected");
                    break;
            }
            
            cell = shareLinkOptionCell;
            
        }
        
    }
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return heighOfFileDetailrow;
    }else{
        return heightOfShareLinkOptionRow;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 10.0;
    
    if (section == 1) {
        height = heightOfShareLinkHeader;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [UIView new];
    
    if (section == 1) {
        
        ShareLinkHeaderCell* shareLinkHeaderCell = [tableView dequeueReusableCellWithIdentifier:shareLinkHeaderIdentifier];
        
        if (shareLinkHeaderCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkHeaderNib owner:self options:nil];
            shareLinkHeaderCell = (ShareLinkHeaderCell *)[topLevelObjects objectAtIndex:0];
        }
        
         shareLinkHeaderCell.titleSection.text = @"Share Link";
        [shareLinkHeaderCell.switchSection setOn:self.isShareLinkEnabled animated:true];
        [shareLinkHeaderCell.switchSection addTarget:self action:@selector(sharedLinkSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        headerView = shareLinkHeaderCell;
        
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 1 && indexPath.row == 2) {
        [self getShareLinkView];
    }
}

#pragma mark - ShareFileOrFolder Delegate Methods

- (void) initLoading {
    
    if (self.loadingView != nil) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
    }
    
    self.loadingView = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
    self.loadingView.delegate = self;
    
    if (IS_IPHONE) {
        [self.view.window addSubview:self.loadingView];
    }else{
        [APP_DELEGATE.splitViewController.view.window addSubview:self.loadingView];
    }
    
    [self.view addSubview:self.loadingView];
    
    self.loadingView.labelText = NSLocalizedString(@"loading", nil);
    self.loadingView.dimBackground = false;
    
    [self.loadingView show:true];
    
    self.view.userInteractionEnabled = false;
    self.navigationController.navigationBar.userInteractionEnabled = false;
    self.view.window.userInteractionEnabled = false;
}

- (void) endLoading {
    
    if (APP_DELEGATE.isLoadingVisible == false) {
        [self.loadingView removeFromSuperview];
        
        self.view.userInteractionEnabled = true;
        self.navigationController.navigationBar.userInteractionEnabled = true;
        self.view.window.userInteractionEnabled = true;
        
    }
}

- (void) errorLogin {
    
    
}

- (void) finishUnShare {
    
    [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    
}

- (void) presentShareOptions:(UIActivityViewController*) activityView{
    
    if (IS_IPHONE) {
        [self presentViewController:activityView animated:true completion:nil];
        [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    }else{
        [self reloadView];
        
        UIPopoverController* activityPopoverController = [[UIPopoverController alloc]initWithContentViewController:activityView];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:2 inSection:1];
        UITableViewCell* cell = [self.shareTableView cellForRowAtIndexPath:indexPath];
        
        [activityPopoverController presentPopoverFromRect:cell.frame inView:self.shareTableView permittedArrowDirections:UIPopoverArrowDirectionUp animated:true];
    }
    
}



@end
