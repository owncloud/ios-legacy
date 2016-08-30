//
//  MoveFile.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/24/12.
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
#import "OverwriteFileOptions.h"
#import "UtilsNetworkRequest.h"
#import "ManageNetworkErrors.h"

@protocol MoveFileDelegate
@optional
- (void)refreshTableFromWebDav;
- (void)initLoading;
- (void)endLoading;
- (void)reloadTableFromDataBase;
- (void)endMoveBackGroundTask;
- (void)errorLogin;
@end

@interface MoveFile : NSObject <OverwriteFileOptionsDelegate, UtilsNetworkRequestDelegate, ManageNetworkErrorsDelegate>

@property (nonatomic, strong) FileDto *selectedFileDto;
@property (nonatomic, strong) NSString *destinationFolder;
@property (nonatomic, strong) NSString *destinyFilename;

@property (nonatomic, weak) __weak id<MoveFileDelegate> delegate;
@property (nonatomic, strong) OverwriteFileOptions *overWritteOption;
@property (nonatomic, strong) UIView *viewToShow;
@property (nonatomic, strong) UtilsNetworkRequest *utilsNetworkRequest;
@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;

-(void) initMoveProcess;

@end
