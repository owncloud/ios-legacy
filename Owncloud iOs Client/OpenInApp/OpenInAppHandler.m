//
//  OpenInAppHandler.m
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 13/12/2017.
//
//

#import "OpenInAppHandler.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "UtilsUrls.h"
#import "ManageFilesDB.h"
#import "UtilsDtos.h"

#define FOLDER_PATH 0
#define FILE_PATH 1


#define FOLDER_PATH 0
#define FILE_PATH 1

@implementation OpenInAppHandler

-(id)initWithLink:(NSURL *)linkURL andUser:(UserDto *) user {

    self = [super init];
    
    if (self) {
        _tappedLinkURL = linkURL;
        _user = user;
    }
    return self;
}

-(void)getRedirection:(NSURL *)privateLink success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {
    
    [[AppDelegate sharedOCCommunication] getFullPathFromPrivateLink:_tappedLinkURL success:^(NSURL *path) {
        success(path.absoluteString);
    } failure:^(NSError *error){
        failure(error);
    }];
}

-(BOOL)isFolder: (NSArray *)queryParameters {
    if (queryParameters.count >= 2) {
        return NO;
    }
    return YES;
}

-(NSMutableArray *)getURlsForFilesWithQueryParameters: (NSMutableArray *)detachedFolderPath andBaseURL: (NSString *)baseURL {
    
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    NSString *tmpURL = baseURL;
    [urls addObject:tmpURL];
    for(int i = 0; i < detachedFolderPath.count; i++) {
        tmpURL = [tmpURL stringByAppendingString:[detachedFolderPath[i] stringByAppendingString: @"/"]];
        [urls addObject:tmpURL];
    }
    
    return urls;
}

-(void)handleLink {
    
    
    
    
}

-(NSMutableArray *)getQueryParameters:(NSString *) url {
    
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    for (NSString *param in [url componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params addObject:[elts lastObject]];
    }
    
    return params;
}

-(void)cacheDownloadedFolder:(NSMutableArray *)downloadedFolder withParent:(FileDto *)parent {
    
<<<<<<< HEAD
    
    for (int i = 1; i < downloadedFolder.count; i++) {
        FileDto *tmpFileDTO = downloadedFolder[i];
        FileDto *cachedFile = [ManageFilesDB getFolderByFilePath:tmpFileDTO.filePath andFileName:tmpFileDTO.fileName];
        if (cachedFile != nil) {
            [downloadedFolder removeObjectAtIndex:i];
        }
    }
    
    [ManageFilesDB insertManyFiles:downloadedFolder ofFileId:5 andUser:APP_DELEGATE.activeUser];
=======
    NSMutableArray *folderToCache = [NSMutableArray new];
    int numberOfFiles = (int) downloadedFolder.count;
    for (int i = 0; i < numberOfFiles; i++) {
        FileDto *tmpFileDTO = downloadedFolder[i];
        tmpFileDTO.filePath = [tmpFileDTO.filePath stringByReplacingOccurrencesOfString:@"/remote.php/webdav/" withString:@""];
        FileDto *fileToCache = [ManageFilesDB getFileDtoByFileName:tmpFileDTO.fileName andFilePath:tmpFileDTO.filePath andUser:_user];
        
        if (fileToCache == nil) {
            [folderToCache addObject:tmpFileDTO];
        }
    }

    [ManageFilesDB insertManyFiles:folderToCache ofFileId:parent.idFile andUser:APP_DELEGATE.activeUser];
>>>>>>> 991cd514... fix for the syncing algorithm in open in app the private links
}

-(void)getFilesFrom:(NSString *)folderPath success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    
    [[AppDelegate sharedOCCommunication] readFolder:folderPath withUserSessionToken:APP_DELEGATE.userSessionCurrentToken onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
        
        NSLog(@"LOG ---> items count = %lu",(unsigned long)items.count);
        success(items);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
        
        NSLog(@"LOG ---> error en la request");
        failure(error);
    }];
    
}

-(void)handleLink:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    
    [self getRedirection:_tappedLinkURL success:^(NSString *redirectedURL) {
        
        
        NSString *fileRedirectedURL = [UtilsUrls getSharedLinkArgumentsFromWebLink:redirectedURL andUser:_user];
        NSArray *queryParameters = [self getQueryParameters:fileRedirectedURL];
        
        NSMutableArray *detachedFolderPath = [[queryParameters[0] componentsSeparatedByString:@"/"] mutableCopy];
        [detachedFolderPath removeObjectAtIndex:0];
        if (![self isFolder:queryParameters]) {
            [detachedFolderPath addObject:queryParameters[1]];
        } else {
            [detachedFolderPath removeLastObject];
        }
        
        __block NSMutableArray *urls = [self getURlsForFilesWithQueryParameters:detachedFolderPath andBaseURL: [UtilsUrls getFullRemoteServerPathWithWebDav:_user]];
        
        __block NSMutableArray *files = [[NSMutableArray alloc] initWithCapacity:urls.count];
        
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        
        dispatch_group_async(group ,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self getFilesFrom:urls[idx] success:^(NSArray *items) {
                    NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
                    files[idx] = directoryList;
                    NSLog(@"LOG ---> success la request de get files con %@", urls[idx]);
                    
                    if (idx == urls.count - 1) {
                        dispatch_group_leave(group);
                    }
                } failure:^(NSError *error) {
                    NSLog(@"LOG ---> failure la request de get files con %@", urls[idx]);
                    //TODO: stop requests and show error message to user.
                }];
            }];
        });
        
        dispatch_group_notify(group ,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            FileDto *parent = [ManageFilesDB getRootFileDtoByUser: _user];
            for (int i = 1; i < files.count; i ++) {
<<<<<<< HEAD
                [self cacheDownloadedFolder:files[i] withParent:parent];
=======
                
                NSString *urlToGetAsParent = urls[i];
                NSString *shortedFileURL = [UtilsUrls getFilePathOnDBByFullPath:urlToGetAsParent andUser:_user];
                NSString *name = [self getFileNameFromURLWithURL:shortedFileURL];
                NSString *path = [self getFilePathFromURLWithURL:shortedFileURL andFileName:name];
                if ([path isEqualToString:@"/remote.php/webdav/"]) {
                    path = @"";
                }
                
                documents = [ManageFilesDB getFileDtoByFileName:name andFilePath:path andUser:_user];
                if (documents != nil) {
//                    documents.filePath = [documents.filePath stringByReplacingOccurrencesOfString:@"/remote.php/webdav" withString:@""];
                    [filesToReturn addObject:documents];
                }
                [self cacheDownloadedFolder:files[i] withParent:documents];

>>>>>>> 991cd514... fix for the syncing algorithm in open in app the private links
            }
            NSLog(@"LOG ---> all requests finished %@", files[0][0]);
        });
        
    } failure:^(NSError *error) {
        NSLog(@"LOG ---> failure del handle link");
    }];
    
}

@end
