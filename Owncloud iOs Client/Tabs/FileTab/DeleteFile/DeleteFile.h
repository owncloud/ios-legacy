//
//  DeleteFile.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 8/17/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "FileDto.h"
#import "ManageNetworkErrors.h"

@protocol DeleteFileDelegate

@optional
- (void)refreshTableFromWebDav;
- (void)initLoading;
- (void)endLoading;
- (void)reloadTableFromDataBase;
- (void)errorLogin;
- (void)removeSelectedIndexPath;
@end

@interface DeleteFile : NSObject <UIAlertViewDelegate, UIActionSheetDelegate, ManageNetworkErrorsDelegate>
  
typedef enum {
    deleteFromServerAndLocal=1,
    deleteFromLocal=2
    
} enumDeleteFrom;

@property(nonatomic, strong) FileDto *file;
@property(nonatomic,weak) __weak id<DeleteFileDelegate> delegate; 
@property(nonatomic,strong)NSString *currentLocalFolder;
@property(nonatomic,strong)UIView *viewToShow;
@property(nonatomic,strong)UIActionSheet *popupQuery;
@property int deleteFromFlag;
@property(nonatomic)BOOL deleteFromFilePreview;
@property(nonatomic)BOOL isFilesDownloadedInFolder;
@property(nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;

- (void)askToDeleteFileByFileDto: (FileDto *) file;
- (void)deleteItemFromDeviceByFileDto: (FileDto *) file;
- (void)errorLogin;

@end
