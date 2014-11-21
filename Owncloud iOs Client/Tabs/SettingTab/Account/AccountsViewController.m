//
//  AccountsViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/1/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "AccountsViewController.h"
#import "AccountCell.h"

#import "UserDto.h"
#import "AddAccountViewController.h"
#import "EditAccountViewController.h"
#import "AppDelegate.h"
#import "constants.h"
#import "UIColor+Constants.h"
#import "DetailViewController.h"
#import "Customization.h"
#import "ManageUsersDB.h"
#import "OCNavigationController.h"
#import "ManageUploadRequest.h"
#import "UtilsFramework.h"
#import "UtilsCookies.h"
#import "ManageCookiesStorageDB.h"
#import "UtilsUrls.h"

@interface AccountsViewController ()

@end

@implementation AccountsViewController

@synthesize tableView = _tableView;
@synthesize listUsers = _listUsers;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

/*-(void)internazionaliceTheInitialInterface {
 _setPassCodeLbl.text = NSLocalizedString(@"title_app_pin", nil);
 //[btnDisconnect setTitle:NSLocalizedString(@"disconnect_button", nil) forState:UIControlStateNormal];
 }*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title=NSLocalizedString(@"manage_accounts", nil);
    //self.listUsers = [ManageUsersDB getAllUsers];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.edgesForExtendedLayout = UIRectCornerAllCorners;
    
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self refreshTable];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

-(void)viewWillLayoutSubviews
{
    [self.tableView reloadData];
}

#pragma mark - Utils

- (void) cancelAllDownloadsOfActiveUser {
    //Cancel downloads in ipad
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate.downloadManager cancelDownloads];
}

#pragma mark - Edit row

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (editing) {
        // you might disable other widgets here... (optional)
        [self.tableView reloadData];
    } else {
        // re-enable disabled widgets (optional)
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if(indexPath.section > 0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"DELETE!!! %d", indexPath.row);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        UserDto *selectedUser = (UserDto *)[self.listUsers objectAtIndex:indexPath.row];
        
        //Cancel downloads of the active user
        if (selectedUser.idUser == app.activeUser.idUser) {
            [self cancelAllDownloadsOfActiveUser];
        }
        
        //Delete the tables of this user
        [ManageUsersDB removeUserAndDataByIdUser: selectedUser.idUser];
        
        //[self cancelUploadsByUser:(UserDto *) selectedUser];
        
        [self performSelectorInBackground:@selector(cancelAndremoveFromTabRecentsAllInfoByUser:) withObject:selectedUser];
        
        //Delete files os user in the system
        NSString *userFolder = [NSString stringWithFormat:@"/%d",selectedUser.idUser];
        NSString *path= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:userFolder];
        
        //NSString *userFolder = [NSString stringWithFormat:@"/%d",selectedUser.idUser];
        //NSString *path= [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:userFolder];
        
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        
        
        //if previeus account is active we active the first by iduser
        if(selectedUser.activeaccount) {
            
            [ManageUsersDB setActiveAccountAutomatically];
            
            //Update in appDelegate the active user
            app.activeUser = [ManageUsersDB getActiveUser];
            
            [self setCookiesOfActiveAccount];
            
            //If ipad, clean the detail view
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                [app presentWithView];
            }
        }
        
        self.listUsers = [ManageUsersDB getAllUsers];
        
        if([self.listUsers count] > 0) {
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        } else {
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            //[appDelegate dismissPopover];
            
            //appDelegate.downloadsArray=[[NSMutableArray alloc]init];
            [appDelegate.downloadManager cancelDownloads];
            appDelegate.uploadArray=[[NSMutableArray alloc]init];
            [appDelegate updateRecents];
            [appDelegate restartAppAfterDeleteAllAccounts];
            
        }
        
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

#pragma mark - UITableView datasource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger n = 0;
    
    if (section==0) {
        n = [self.listUsers count];
    }else if (section==1) {
        n = 1;
    }
    
    return n;
}


// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"AccountCell";
    
    AccountCell *cell = (AccountCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		
		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"AccountCell" owner:self options:nil];
		
		for (id currentObject in topLevelObjects){
			if ([currentObject isKindOfClass:[UITableViewCell class]]){
				cell =  (AccountCell *) currentObject;
				break;
			}
		}
	}
    
   /* UIFont *cellFont = [UIFont systemFontOfSize:16.0];
    UIFont *cellBoldFont = [UIFont boldSystemFontOfSize:16.0];
    cell.textLabel.font=cellFont;*/
    
    if (indexPath.section==0) {
        
        cell.delegate = self;
        
        [cell.activeButton setTag:indexPath.row];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.userName.text = ((UserDto *) [self.listUsers objectAtIndex:indexPath.row]).username;
        
        //If saml needs change the name to utf8
        if (k_is_sso_active) {
            cell.userName.text = [cell.userName.text stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        
        cell.urlServer.text = ((UserDto *) [self.listUsers objectAtIndex:indexPath.row]).url;
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
       /* if(IS_PORTRAIT && IS_IPHONE) {
            
            [cell.urlServer setFrame:CGRectMake(52.0, 20.0, 250.0, 21.0)];
            
        } else {
            [cell.urlServer setFrame:CGRectMake(52.0, 20.0, 250.0, 21.0)];
        }*/
        
        
        if(((UserDto *) [self.listUsers objectAtIndex:indexPath.row]).activeaccount){
            [cell.activeButton setImage:[UIImage imageNamed:@"radio_checked.png"] forState:UIControlStateNormal];
            
        }else {
            [cell.activeButton setImage:[UIImage imageNamed:@"radio_unchecked.png"] forState:UIControlStateNormal];
        }
        
    }else if (indexPath.section==1) {
        
        UIFont *boldFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
        
        switch (indexPath.row) {
            case 0:
                cell.selectionStyle=UITableViewCellSelectionStyleBlue;
                cell.textLabel.font=boldFont;
                cell.textLabel.textAlignment=NSTextAlignmentCenter;
                cell.textLabel.text=NSLocalizedString(@"add_new_account", nil);
                cell.editing = NO;
                break;
            default:
                break;
        }
    }
    
    return cell;
}



// Returns the table view managed by the controller object.
/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
 {
 //Only show the section title if there are rows in it
 
 }*/

// Asks the data source to return the titles for the sections for a table view.
/*- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
 {
 // The commented part is for the version with searchField
 
 
 return ;
 }*/

// Asks the data source to return the index of the section having the given title and section title index.
/*- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
 {
 
 
 return ;
 }*/

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{

    
    //Edit Account
    EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:(UserDto *)[self.listUsers objectAtIndex:indexPath.row]];
    
    if (IS_IPHONE)
    {
        viewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (IS_IOS8) {
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
        }
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }
    
}

// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        //Cancel downloads
        [self cancelAllDownloadsOfActiveUser];
        
        //Method to change the account
        AccountCell *cell = (AccountCell *) [tableView cellForRowAtIndexPath:indexPath];
        [cell activeAccount:nil];
        
        
    }else if (indexPath.section == 1) {
        
        switch (indexPath.row) {
            case 0:
                [self goToAddAccount];
                break;
            default:
                break;
        }
    }
}

-(void)goToAddAccount {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Add Account
    AddAccountViewController *viewController = [[AddAccountViewController alloc]initWithNibName:@"AddAccountViewController_iPhone" bundle:nil];
    viewController.delegate = self;
    
    if (IS_IPHONE)
    {
        viewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        
        if (IS_IOS8) {
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
        }
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }
    
}

-(void)activeAccountByPosition:(int)position {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    UserDto *selectedUser = (UserDto *)[self.listUsers objectAtIndex:position];
    
    if (app.activeUser.idUser != selectedUser.idUser) {
        //Cancel downloads of the previous user
        [self cancelAllDownloadsOfActiveUser];
        
        //If ipad, clean the detail view
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [app presentWithView];
        }
        
        [ManageUsersDB setAllUsersNoActive];
        [ManageUsersDB setActiveAccountByIdUser:selectedUser.idUser];
        selectedUser.activeaccount = YES;
        
        //Restore the cookies of the future activeUser
        //1- Storage the new cookies on the Database
        [UtilsCookies setOnDBStorageCookiesByUser:app.activeUser];
        //2- Clean the cookies storage
        [UtilsFramework deleteAllCookies];
        //3- We restore the previous cookies of the active user on the System cookies storage
        [UtilsCookies setOnSystemStorageCookiesByUser:selectedUser];
        //4- We delete the cookies of the active user on the databse because it could change and it is not necessary keep them there
        [ManageCookiesStorageDB deleteCookiesByUser:selectedUser];
        
        //Change the active user in appDelegate global variable
        app.activeUser = selectedUser;
        
        //Check if the server is Chunk
        [self performSelectorInBackground:@selector(checkShareItemsInAppDelegate) withObject:nil];
        
        [self eraseURLCache];
        
        self.listUsers = [ManageUsersDB getAllUsers];
        [self.tableView reloadData];
        
        //We get the current folder to create the local tree
        //we create the user folder to haver multiuser
        NSString *currentLocalFileToCreateFolder = [NSString stringWithFormat:@"%@%d/",[UtilsUrls getOwnCloudFilePath],selectedUser.idUser];
        DLog(@"current: %@", currentLocalFileToCreateFolder);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:currentLocalFileToCreateFolder]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:currentLocalFileToCreateFolder withIntermediateDirectories:NO attributes:nil error:&error];
            DLog(@"Error: %@", [error localizedDescription]);
        }
        app.isNewUser = YES;
    }
}

#pragma mark - Delete cache HTTP

- (void)eraseCredentials
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSString *connectURL =[NSString stringWithFormat:@"%@%@",app.activeUser.url,k_url_webdav_server];
    
    NSURLCredentialStorage *credentialsStorage = [NSURLCredentialStorage sharedCredentialStorage];
    NSDictionary *allCredentials = [credentialsStorage allCredentials];
    
    if ([allCredentials count] > 0)
    {
        for (NSURLProtectionSpace *protectionSpace in allCredentials)
        {
            DLog(@"Protetion espace: %@", [protectionSpace host]);
            
            if ([[protectionSpace host] isEqualToString:connectURL])
            {
                DLog(@"Credentials erase");
                NSDictionary *credentials = [credentialsStorage credentialsForProtectionSpace:protectionSpace];
                for (NSString *credentialKey in credentials)
                {
                    [credentialsStorage removeCredential:[credentials objectForKey:credentialKey] forProtectionSpace:protectionSpace];
                }
            }
        }
    }
}

- (void)eraseURLCache
{
    //  NSURL *loginUrl = [NSURL URLWithString:self.connectString];
    //  NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc]initWithURL:loginUrl];
    // [NSMutableURLRequest requestWithURL:loginUrl];
    //  [[NSURLCache sharedURLCache] removeCachedResponseForRequest:urlRequest];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}


#pragma mark - Resizing label
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        
        AccountCell *cell = (AccountCell *) [self.tableView cellForRowAtIndexPath:indexPath];
        
        [cell.urlServer setFrame:CGRectMake(52, 20, 150, 21)];
        cell.urlServer.lineBreakMode = NSLineBreakByTruncatingTail;
        
        return UITableViewCellEditingStyleDelete;
    }
    else {
        // do your thing
        return UITableViewCellEditingStyleDelete;
    }
}

-(void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountCell *cell = (AccountCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    
    [cell.urlServer setFrame:CGRectMake(52, 20, 204, 21)];
    cell.urlServer.lineBreakMode = NSLineBreakByTruncatingTail;
    
}

#pragma mark - Check Server version in order to use chunks to upload or not
- (void)checkShareItemsInAppDelegate{
 
 AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
 [appDelegate checkIfServerSupportThings];
}





#pragma mark - AddAccountDelegate

- (void) refreshTable {
    self.listUsers = [ManageUsersDB getAllUsers];
    [self.tableView reloadData];
}

//-----------------------------------
/// @name setCookiesOfActiveAccount
///-----------------------------------

/**
 * Method to delete the current cookies and add the cookies of the active account
 *
 * @warning we have to take in account that the cookies of the active account must to be in the database
 */
- (void) setCookiesOfActiveAccount {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //1- Delete the current cookies because we delete the current active user
    [UtilsFramework deleteAllCookies];
    //2- We restore the previous cookies of the active user on the System cookies storage
    [UtilsCookies setOnSystemStorageCookiesByUser:app.activeUser];
    //3- We delete the cookies of the active user on the databse because it could change and it is not necessary keep them there
    [ManageCookiesStorageDB deleteCookiesByUser:app.activeUser];
}

///-----------------------------------
/// @name cancelAndremoveFromTabRecentsAllInfoByUser
///-----------------------------------

/**
 * This method cancel the uploads of a deleted user and after that remove all the other files from Recents Tab
 *
 * @param UserDto
 *
 */

- (void) cancelAndremoveFromTabRecentsAllInfoByUser:(UserDto *) selectedUser {
    
    //1- - We cancell all the downloads
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //Create an array with the data of all uploads
    __block NSArray *uploadsArray = [NSArray arrayWithArray:appDelegate.uploadArray];
    
    //Var to use the current ManageUploadRequest
    __block ManageUploadRequest *currentManageUploadRequest = nil;
    
    
    //Make a loop for all objects of uploadsArray.
    [uploadsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        currentManageUploadRequest = obj;
        
        if (currentManageUploadRequest.userUploading.idUser == selectedUser.idUser) {
            [currentManageUploadRequest cancelUpload];
        }
        
        //2- Clean the recent view
        if ([uploadsArray count] == idx) {
            
            DLog(@"All canceled. Now we clean the view");
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            //Remove from Recents tab all the info of this user
            [app removeFromTabRecentsAllInfoByUser:selectedUser];
        }
    }];
    
}

@end
