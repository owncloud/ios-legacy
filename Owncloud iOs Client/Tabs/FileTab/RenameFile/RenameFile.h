//
//  RenameFile.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/9/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "FileDto.h"
#import "UserDto.h"
#import "UtilsNetworkRequest.h"
#import "ManageNetworkErrors.h"


@protocol RenameDelegate
@optional
- (void)refreshTableFromWebDav;
- (void)initLoading;
- (void)endLoading;
- (void)reloadTableFromDataBase;
- (void) errorLogin;
@end

@interface RenameFile : NSObject <UIAlertViewDelegate, UITextFieldDelegate, UtilsNetworkRequestDelegate, ManageNetworkErrorsDelegate>

@property(nonatomic, strong) UIAlertView *renameAlertView;
@property(nonatomic, strong) FileDto *selectedFileDto;
@property(nonatomic,weak) __weak id<RenameDelegate> delegate;
@property(nonatomic, strong) NSString *currentRemoteFolder;
@property(nonatomic, strong) NSString *currentLocalFolder;
@property(nonatomic, strong) NSArray *currentDirectoryArray;
@property(nonatomic, strong) UserDto *mUser;
@property(nonatomic, strong) NSString *mNewName;
@property(nonatomic, strong) NSString *destinationFile;
@property(nonatomic, strong) UtilsNetworkRequest *utilsNetworkRequest;
@property(nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;

- (void)showRenameFile: (FileDto *) file;

@end
