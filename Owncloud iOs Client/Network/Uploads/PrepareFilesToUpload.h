//
//  PrepareFilesToUpload.h
//  Owncloud iOs Client
//
//  Class that receive a info of items selected by the user
//  and Store each item like a file.
//  Then send to file to Upload method.
//
//  Created by Gonzalo Gonzalez on 12/09/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import <Foundation/Foundation.h>
#import "UserDto.h"
#import "ManageUploadRequest.h"

//Notification to init and end loading screen in main view
extern NSString *EndLoadingFileListNotification;
extern NSString *InitLoadingFileListNotification;
extern NSString *ReloadFileListFromDataBaseNotification;


@protocol PrepareFilesToUploadDelegate

/*
 *Delegate to communicate with the Appdelegate side
 */
@optional
- (void)refreshAfterUploadAllFiles:(NSString *) currentRemoteFolder;
- (void)reloadTableFromDataBase;
- (void)errorWhileUpload;
- (void)errorLogin;
@end



@interface PrepareFilesToUpload : NSObject <ManageUploadRequestDelegate> {
    
    /*
     *Delegate
     */
    id<PrepareFilesToUploadDelegate> _delegate;

    
    NSMutableArray *_listOfFilesToUpload;
    NSMutableArray *_arrayOfRemoteurl;
    int _counterUploadFiles;
    int _positionOfCurrentUploadInArray;
    
    NSMutableArray *_listOfUploadOfflineToGenerateSQL;
}

@property(nonatomic,strong) id<PrepareFilesToUploadDelegate> delegate;
@property(nonatomic,strong) NSMutableArray *listOfFilesToUpload;
@property(nonatomic,strong) NSMutableArray *arrayOfRemoteurl;
@property(nonatomic) int counterUploadFiles;
@property(nonatomic,strong) NSMutableArray *listOfUploadOfflineToGenerateSQL;
@property(nonatomic) int positionOfCurrentUploadInArray;

@property(nonatomic,strong) NSMutableArray *listOfAssetsToUpload;
@property(nonatomic,strong) NSString * nameRemoteInstantUploadFolder;
@property(nonatomic,strong) NSString * pathRemoteInstantUpload;

@property (nonatomic, strong) UtilsNetworkRequest *utilsNetworkRequest;


/*
 * This method is called to add a list of files to the upload list
 */
- (void) addFilesToUpload:(NSArray *) info andRemoteFoldersToUpload:(NSMutableArray *) arrayOfRemoteurl;
/*
 *This method is called to begin the upload transaction. Is called after finish an upload
 */
- (void) sendFileToUploadByUploadOfflineDto:(UploadsOfflineDto *) currentUpload;



- (void) addAssetsToUpload:(NSArray *) newAsssets andRemoteFolder:(NSString *) remoteFolderToUpload;


@end
