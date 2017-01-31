//
//  ManageDownloads.m
//  Owncloud iOs Client
//
// This class manage the array of downloads objects
// in order to download as a FIFO list.
//
//  Created by Gonzalo Gonzalez on 14/08/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "ManageDownloads.h"
#import "ManageFilesDB.h"
#import "Customization.h"
#import "AppDelegate.h"
#import "FilesViewController.h"
#import "FilePreviewViewController.h"
#import "DetailViewController.h"
#import "OCCommunication.h"
#import "OCURLSessionManager.h"
#import "ManageUsersDB.h"


@interface ManageDownloads()

@property (nonatomic, strong) NSMutableArray *downloads;
@property (nonatomic) BOOL enteringInBackgroundFetch;
@property (nonatomic) BOOL isCancelingAllDownloads;

@end

@implementation ManageDownloads

#pragma mark - Init Methods

+(ManageDownloads *)singleton {
    static dispatch_once_t pred;
    static ManageDownloads *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[ManageDownloads alloc] init];
    });
    return shared;
}

- (id)init {
    
    if (self = [super init]) {
        //Custom init
        _downloads = [NSMutableArray new];
        _enteringInBackgroundFetch = NO;
        _isCancelingAllDownloads = NO;
        
        //Add observer for notifications about network not reachable in uploads
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelDownloadsAndRefreshInterface) name:NotReachableNetworkForDownloadsNotification object:nil];
    }
    return self;
}

- (void) cancelDownloadsAndRefreshInterface{
    [self cancelDownloads];
    
    if (IS_IPHONE) {
        [[NSNotificationCenter defaultCenter] postNotificationName:iPhoneCleanPreviewNotification object:nil];
    }else{
        [[NSNotificationCenter defaultCenter] postNotificationName:IpadCleanPreviewNotification object:nil];
    }
}

- (void)cancelDownloads {
    
    self.isCancelingAllDownloads = YES;
    NSArray *temp = [NSArray arrayWithArray:self.downloads];
    
    UserDto *user = nil;
    
    for (Download *download in temp) {
        if (!user) {
            user = [ManageUsersDB getUserByIdUser:download.fileDto.userId];
        }
        download.user = user;
        [download cancelDownload];
    }
    
    self.isCancelingAllDownloads = NO;
    
}

#pragma mark - Getters

- (NSArray *) getDownloads{
    
    return [NSArray arrayWithArray:self.downloads];
}

#pragma mark - Public Methods


- (void) addDownload:(Download *)download{
    
    [[AppDelegate sharedOCCommunication].downloadSessionManager.operationQueue cancelAllOperations];
    
    if (self.downloads.count > 0) {
        for (Download *temp in self.downloads) {
            if (temp.downloadTask.state == NSURLSessionTaskStateRunning) {
                temp.isForceCanceling = YES;
                [temp.downloadTask cancel];
            }
        }
        
        NSMutableArray *downs = [NSMutableArray arrayWithArray:self.downloads];
        //To be sure that the download is not duplicated we remove all the identical
        for (Download *temp in self.downloads) {
            if ([temp.fileDto.localFolder isEqualToString:download.fileDto.localFolder]) {
                [downs removeObjectIdenticalTo:temp];
                break;
            }
        }
        self.downloads = [NSMutableArray arrayWithArray:downs];
    }
    
    if (!download.delegate) {
        download.delegate = self;
    }
    
    if (download.downloadTask) {
        [self.downloads addObject:download];
        if (download.downloadTask.state != NSURLSessionTaskStateRunning) {
            download.isForceCanceling = NO;
            [download.downloadTask resume];
        }
    }
}

- (void) addSimpleDownload:(Download *)download{
    
    if (self.downloads.count > 0) {
        BOOL exist = NO;
        for (Download *temp in self.downloads) {
            if ([temp.fileDto.localFolder isEqual:download.fileDto.localFolder]) {
                exist = YES;
                break;
            }
        }
        if (exist == NO) {
            [self.downloads addObject:download];
        }

    }else{
        [self.downloads addObject:download];
    }
}

- (void) removeDownload:(Download *)download{
    
        
        BOOL exist = NO;
        
        for (Download *temp in self.downloads) {
            if ([temp isEqual:download]) {
                exist = YES;
                break;
            }
        }
        
        if (exist) {
            
            NSMutableArray *downs = [NSMutableArray arrayWithArray:self.downloads];
            [downs removeObjectIdenticalTo:download];
            self.downloads = [NSMutableArray arrayWithArray:downs];
            
            if (self.downloads.count > 0 && self.isCancelingAllDownloads == NO) {
                [self resumeNextDownload];
            }
        }
    
}

- (void) changeBehaviourForBackgroundFetch:(BOOL)enter{
    
    if (self.downloads.count > 0) {
        for (Download *download in self.downloads) {
            download.isFromBackground = enter;
        }
    }
    
}

#pragma mark - Private Methods

- (void) resumeNextDownload {
    
    if (self.downloads.count > 0) {
        Download *download = [self.downloads lastObject];
        [download processToDownloadTheFile];
    }
}

- (void) cancelDownloadWithFileDto:(FileDto *)file{
    
    for (Download *temp in self.downloads) {
        if ([temp.fileDto.localFolder isEqualToString:file.localFolder]){
            [temp cancelDownload];
            break;
        }
    }
}

- (void) completeDownloadWithFileDto:(FileDto*)file{
    
    for (Download *temp in self.downloads) {
        if ([temp.fileDto.localFolder isEqualToString:file.localFolder]){
            [temp updateDataDownload];
            [temp setDownloadTaskIdentifierValid:NO];
            break;
        }
    }
    
}

- (void) completeDownloadFailedWithFileDto:(FileDto *)file{
    
    for (Download *temp in self.downloads) {
        if ([temp.fileDto.localFolder isEqualToString:file.localFolder]){
            [temp setDownloadTaskIdentifierValid:NO];
            [temp failureDownloadProcess];
            break;
        }
    }
}

- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{
    //Not use in this class
}

- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
   //Not use in this class
}

- (void)errorLogin{
    
    NSLog(@"Manage Downloads: ERROR LOGIN");
    
    NSMutableArray *downloadsFromDB = [NSMutableArray new];
    [downloadsFromDB addObjectsFromArray:[ManageFilesDB getFilesByDownloadStatus:downloading andUser:APP_DELEGATE.activeUser]];
    
    //Put "notdownload" state all files in download
    for (FileDto *file in downloadsFromDB) {
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:notDownload];
    }
    
    [self reloadFileList];
}

- (void)updateOrCancelTheDownload:(id)download{
    //Not use in this class
}

#pragma mark - Download Delegate Methods

- (void)downloadCompleted:(FileDto*)fileDto{
    
    [self completeDownloadWithFileDto:fileDto];
    
}


- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    [self completeDownloadFailedWithFileDto:fileDto];
    
}

#pragma mark - FileList

- (void)reloadFileList{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [app.presentFilesViewController reloadTableFromDataBase];
}


@end
