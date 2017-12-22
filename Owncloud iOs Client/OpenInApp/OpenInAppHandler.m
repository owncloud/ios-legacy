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

<<<<<<< HEAD
-(NSMutableArray *)getQueryParameters:(NSString *) url {
    
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    for (NSString *param in [url componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params addObject:[elts lastObject]];
    }
    
    return params;
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
    
    [self getRedirection:_tappedLinkURL success:^(NSString *redirectedURL) {
        NSArray *queryParameters = [self getQueryParameters:redirectedURL];
        NSMutableArray *detachedFolderPath = [[queryParameters[0] componentsSeparatedByString:@"/"] mutableCopy];
        [detachedFolderPath removeObjectAtIndex:0];
        if (![self isFolder:queryParameters]) {
            [detachedFolderPath addObject:queryParameters[1]];
        } else {
            [detachedFolderPath removeLastObject];
        }
        
        NSMutableArray *urls = [self getURlsForFilesWithQueryParameters:detachedFolderPath andBaseURL:@"https://pablos-mbp.solidgear.prv/remote.php/webdav/"];
        
        FileDto *rootFolder = [ManageFilesDB getRootFileDtoByUser: APP_DELEGATE.activeUser];
        
        for(int i = 0; i < urls.count; i++) {
            [self getFilesFrom:urls[i] success:^(NSArray *items) {
                NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
                if (i == 0) {
                    [self cacheDownloadedFolder:directoryList withParent:rootFolder];
                }
                
                NSLog(@"LOG ---> success la request de get files con %@", urls[i]);
            } failure:^(NSError *error) {
                NSLog(@"LOG ---> failure la request de get files con %@", urls[i]);
                
            }];
        }
    } failure:^(NSError *error) {
        NSLog(@"LOG ---> failure del handle link");

    }];
    
    
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

-(void)cacheDownloadedFolder:(NSMutableArray *)downloadedFolder withParent:(FileDto *)parent {
    
    [downloadedFolder removeObjectAtIndex:0];
    
    for (int i = 0; i < downloadedFolder.count; i++) {
        FileDto *tmpFileDTO = downloadedFolder[i];
        FileDto *cachedFile = [ManageFilesDB getFolderByFilePath:tmpFileDTO.filePath andFileName:tmpFileDTO.fileName];
        if (cachedFile != nil) {
            [downloadedFolder removeObjectAtIndex:i];
        }
    }
    
    [ManageFilesDB insertManyFiles:downloadedFolder ofFileId:parent.idFile andUser:APP_DELEGATE.activeUser];

-(NSString *)transformURL:(NSURL *)redirectedURL {
    
    NSMutableArray *params = [self queryDictionary:redirectedURL.absoluteString];
    NSString *folderName = [params[FOLDER_PATH] substringFromIndex:1];
    NSString *fileName = [[NSString alloc] init];
    
    if (params.count < 2) {
        fileName = @"";
    } else {
        fileName = params[FILE_PATH];
    }
    
    NSString *finalPathInServer = [NSString stringWithFormat:@"%@%@%@%@",[UtilsUrls getFullRemoteServerPathWithWebDav:_user],folderName, @"/",fileName];
    return finalPathInServer;
}

-(void)handleLink:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {
    [self getRedirection:_tappedLinkURL success:^(NSString *redirectedURL) {

        [self getFilesFrom:redirectedURL success:^(NSArray *items){
            NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
//            [self cacheDownloadedFolder:directoryList];
            success(redirectedURL);
        } failure:^(NSError *error) {
            failure(error);
        }];
        
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(void)cacheDownloadedFolder:(NSMutableArray *)downloadedFolder {
    
    FileDto *fileToBeOpened = downloadedFolder[0];
    
    FileDto *cachedFile = [ManageFilesDB getFolderByFilePath:fileToBeOpened.filePath andFileName:fileToBeOpened.fileName];
    
    if (cachedFile == nil) {
        [ManageFilesDB insertManyFiles:downloadedFolder ofFileId:17000 andUser:APP_DELEGATE.activeUser];
    }
    
}

-(void)cachePreviousFolders: (NSString *)fullPath {
    NSArray *elts = [fullPath componentsSeparatedByString:@"/"];
    
    FileDto *rootFolder = [ManageFilesDB getRootFileDtoByUser: APP_DELEGATE.activeUser];
    NSString *url = rootFolder.filePath;
    for (int i = 5; i < elts.count - 1; i++) {
        NSString *tmp = elts[i];
        tmp = [tmp stringByAppendingString:@"/"];
        url = [url stringByAppendingString:tmp];
        NSLog(@"Log ---> URL Siguiente = %@", url);
    }
}

-(NSMutableArray *)queryDictionary:(NSString *) url
{
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    for (NSString *param in [url componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params addObject:[elts lastObject]];
    }
    
    return params;
}

@end
