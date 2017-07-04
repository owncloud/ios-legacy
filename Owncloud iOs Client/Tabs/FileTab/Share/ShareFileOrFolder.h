//
//  ShareFileOrFolder.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 1/10/14.
//  Edited by Noelia Alvarez
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "FileDto.h"
#import "ShareUtils.h"

@class OCSharedDto;

@protocol ShareFileOrFolderDelegate <NSObject>

@optional
- (void) initLoading;
- (void) endLoading;
- (void) errorLogin;
- (void) sharelinkOptionsUpdated;
- (void) finishCheckSharesAndReloadShareView;
@end


@interface ShareFileOrFolder : NSObject <UIActionSheetDelegate,UIAlertViewDelegate,ManageNetworkErrorsDelegate>

@property (nonatomic, strong) FileDto *file;
@property (nonatomic, strong) OCSharedDto *shareDto;
@property (nonatomic, strong) UIView *viewToShow;
@property (nonatomic, strong) id<ShareFileOrFolderDelegate> delegate;
@property (nonatomic, strong) UIPopoverController *activityPopoverController;
//this bool is to indicate if the parent view is a cell
@property (nonatomic)  BOOL isTheParentViewACell;
//this CGRect is to pass the cell frame of the file list
@property (nonatomic) CGRect cellFrame;
@property (nonatomic, strong) UIBarButtonItem *parentButton;
//This view is to show the Popover with the share link options
@property (nonatomic, strong) UIView *parentView;
@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;


///-----------------------------------
/// @name Unshare the file
///-----------------------------------

/**
 * This method unshare the file/folder
 *
 * @param idRemoteShared -> The id of the remote share
 */
- (void)unshareTheFileByIdRemoteShared:(NSInteger)idRemoteShared;



///-----------------------------------
/// @name create share link
///-----------------------------------
/**
 * Method to share the file from file or from sharedDto
 *
 */
- (void) doRequestCreateShareLinkOfFile:(FileDto *)file withPassword:(NSString *)password expirationTime:(NSString*)expirationTime publicUpload:(NSString *)publicUpload linkName:(NSString *)linkName andPermissions:(NSInteger)permissions;

///-----------------------------------
/// @name Update the share link with password protect
///-----------------------------------
/**
 * This method update the file/folder share
 *
 */
- (void) doRequestUpdateShareLink:(OCSharedDto *)ocShare withPassword:(NSString*)password expirationTime:(NSString*)expirationTime publicUpload:(NSString *)publicUpload linkName:(NSString *)linkName andPermissions:(NSInteger)permissions;

/**
 * Check if the file is shared in the server side. If yes, update the database with update data
 *
 * @param FileDto -> The file/folder object
 */
- (void) checkSharedStatusOfFile:(FileDto *) file;

@end
