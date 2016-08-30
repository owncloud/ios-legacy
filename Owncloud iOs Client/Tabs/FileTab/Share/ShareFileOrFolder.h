//
//  ShareFileOrFolder.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 1/10/14.
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

@class OCSharedDto;

@protocol ShareFileOrFolderDelegate <NSObject>

@optional
- (void) initLoading;
- (void) endLoading;
- (void) errorLogin;
- (void) finishUnShareWithStatus:(BOOL)successful;
- (void) finishShareWithStatus:(BOOL)successful andWithOptions:(UIActivityViewController*) activityView;
- (void) finishUpdateShareWithStatus:(BOOL)successful;
- (void) finishCheckSharedStatusOfFile:(BOOL)successful;
@end


@interface ShareFileOrFolder : NSObject <UIActionSheetDelegate,UITextFieldDelegate,UIAlertViewDelegate,ManageNetworkErrorsDelegate>

@property (nonatomic, strong) FileDto *file;
@property (nonatomic, strong) OCSharedDto *shareDto;
@property (nonatomic, strong) UIActionSheet *shareActionSheet;
//This view is to show the shareActionSheet
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
@property(nonatomic, strong) UIAlertView *shareProtectedAlertView;
@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;


- (void) showShareActionSheetForFile:(FileDto *) file;

///-----------------------------------
/// @name Present Share Action Sheet For Token
///-----------------------------------

/**
 * This method show a Share View using a share link
 *
 * @param sharedLink -> NSString
 *
 */
- (void) presentShareActionSheetForToken:(NSString *)sharedLink withPassword:(BOOL) isPasswordSet;



///-----------------------------------
/// @name Unshare the file
///-----------------------------------

/**
 * This method unshares the file/folder
 *
 * @param OCSharedDto -> The shared file/folder
 */
- (void) unshareTheFile: (OCSharedDto *)sharedByLink;

///-----------------------------------
/// @name Click on share link from file
///-----------------------------------

/**
 * Method to share the file from file or from sharedDto
 *
 * @param isFile -> BOOL. Distinct between is fileDto or shareDto
 */
- (void) clickOnShareLinkFromFileDto:(BOOL)isFileDto;


-(void)doRequestSharedLinkWithPath: (NSString *)filePath andPassword: (NSString *)password;

/**
 * This method unshares the file/folder
 *
 * @param OCSharedDto -> The shared file/folder
 */
- (void) updateShareLink:(OCSharedDto *)ocShare withPassword:(NSString*)password expirationTime:(NSString*)expirationTime permissions:(NSInteger)permissions;

/**
 * Check if the file is shared in the server side. If yes, update the database with update data
 *
 * @param FileDto -> The file/folder object
 */
- (void) checkSharedStatusOfFile:(FileDto *) file;

@end
