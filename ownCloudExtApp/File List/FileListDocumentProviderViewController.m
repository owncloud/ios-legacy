//
//  FileListDocumentProviderViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 24/11/14.
//
//

#import "FileListDocumentProviderViewController.h"
#import "FileDto.h"
#import "UserDto.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"

NSString *userHasChangeNotification = @"userHasChangeNotification";

@interface FileListDocumentProviderViewController ()

@end

@implementation FileListDocumentProviderViewController

#pragma mark Load View Life

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(delay) withObject:nil afterDelay:2.0];
}

- (void) delay {
    DLog(@"Delay");
 
    [self.view.window layoutSubviews];
    [self.view.window layoutIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath: indexPath animated:YES];
    
    FileDto *file = (FileDto *)[[self.sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    
    if (file.isDirectory) {
        [self checkBeforeNavigationToFolder:file];
    } else {
        //TODO: here we should return the file to the document picker or download it
    }
}

- (void) checkBeforeNavigationToFolder:(FileDto *) file {
    
    //Check if the user is the same and does not change
    if ([self isTheSameUserHereAndOnTheDatabase]) {
        
        if ([ManageFilesDB getFilesByFileIdForActiveUser: (int)file.idFile].count > 0) {
            [self navigateToFile:file];
        } else {
            [self initLoading];
            [self loadRemote:file andNavigateIfIsNecessary:YES];
        }
        
    } else {
        [self showErrorUserHasChange];
    }
}

- (void) reloadCurrentFolder {
    //Check if the user is the same and does not change
    if ([self isTheSameUserHereAndOnTheDatabase]) {
        [self loadRemote:self.currentFolder andNavigateIfIsNecessary:NO];
    } else {
        [self showErrorUserHasChange];
    }
}

#pragma mark - Check User

- (BOOL) isTheSameUserHereAndOnTheDatabase {
    
    UserDto *userFromDB = [ManageUsersDB getActiveUser];
    
    BOOL isTheSameUser = NO;
    
    if (userFromDB.idUser == self.user.idUser) {
        self.user = userFromDB;
        isTheSameUser = YES;
    }
    
    return isTheSameUser;
    
}

- (void) showErrorUserHasChange {
    //The user has change
    
    UIAlertController *alert =   [UIAlertController
                                  alertControllerWithTitle:@""
                                  message:@"The user has change on the ownCloud App" //TODO: add a string error internationzalized
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:NSLocalizedString(@"ok", nil)
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             [super dismissViewControllerAnimated:YES completion:^{
                                 [[NSNotificationCenter defaultCenter] postNotificationName: userHasChangeNotification object: nil];
                             }];
                         }];
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Navigation
- (void) navigateToFile:(FileDto *) file {
    //Method to be overwritten
    FileListDocumentProviderViewController *filesViewController = [[FileListDocumentProviderViewController alloc] initWithNibName:@"FileListDocumentProviderViewController" onFolder:file];
    
    [[self navigationController] pushViewController:filesViewController animated:YES];
}


@end
