//
//  UtilsDtos.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 12/3/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsDtos.h"
#import "constants.h"
#import "UserDto.h"
#import "OCFileDto.h"
#import "UtilsUrls.h"

@implementation UtilsDtos

//This method return the part of file path that is valid in the data base
+(NSString *) getDbBFolderPathFromFullFolderPath:(NSString *) fullFilePath andUser:(UserDto *) user {
    
    NSString *output = @"";
    
    //if the path the receive is:  /owncloud/remote.php/webdav/Fotos11/
    //we have to return: Fotos11/
    //if the path the receive is: /owncloud/remote.php/webdav/Fotos11/AA/
    //we have to return: Fotos11/AA/
    
    //0.- Catch the length  
    
    //DLog(@"User url is:%@", currentUser.url);
    NSString *serverURL=@"";
    
    NSArray *splitePath = [user.url componentsSeparatedByString:@"/"];
    
    for (int i = 0; i < [splitePath count]; i++) {
        if (i > 2) {
            serverURL = [NSString stringWithFormat:@"%@%@", serverURL, [splitePath objectAtIndex:i]];
        }
        //If the address of the server is like: daily.owncloud.com/master/owncloud/remote.php/webdav/
        if ([splitePath count] > 4) {
            if (i > 2 && i < [splitePath count]-2) {
                serverURL = [NSString stringWithFormat:@"%@/",serverURL];
            }
        }
    }
    
    DLog(@"Server URL is: %@", serverURL);
    
    NSUInteger serverLength;
    
    if ([serverURL isEqualToString:@""]) {
       serverLength = [[NSString stringWithFormat:@"%@", k_url_webdav_server]length];
       serverLength++;
    }else{
       serverLength = [[NSString stringWithFormat:@"/%@/%@",serverURL, k_url_webdav_server]length];
    }
    
   // NSUInteger serverLength=[[NSString stringWithFormat:@"/owncloud/%@", k_url_webdav_server]length];
   // NSUInteger userUrlLength= [currentUser.url length];
    
    //1.- Quit the part of the server
    output= [fullFilePath substringFromIndex:(serverLength)];
    
  //  DLog(@"Path folder for database: %@", output);
    
    return output;
}

//This method return the part of file path that is valid in the data base
+(NSString *) getDbBFilePathFromFullFilePath:(NSString *) fullFilePath andUser:(UserDto *) user {
    
    DLog(@"full file path: %@", fullFilePath);
    NSString *output = @"";
    
    //if the path the receive is: http:\//domain/owncloud/remote.php/webdav/Fotos11/perico2.txt
    //we have to return: Fotos11/
    //if the path the receive is: http:\//domain/owncloud/remote.php/webdav/Fotos11/AA/perico2.txt
    //we have to return: Fotos11/AA/

    //1.- Quit the part of the server
    NSUInteger serverLength=[[NSString stringWithFormat:@"%@", k_url_webdav_server]length];
    NSUInteger userUrlLength= [user.url length];
    
    fullFilePath= [fullFilePath substringFromIndex:(serverLength+userUrlLength)];
    
    //2.- Quit the name
    NSArray *splitePath = [fullFilePath componentsSeparatedByString:@"/"];
    
    for (int i = 0; i < [splitePath count]; i++) {
        
        if (i != [splitePath count]-1) {
            
            output = [NSString stringWithFormat:@"%@%@/", output, [splitePath objectAtIndex:i]];
        }
    }
    
  //  DLog(@"output before the substring: %@", output);
    
    //output=[output substringFromIndex:1];
    
    
    return output;
}


//This method return de newfolderpath to find a folder object in DataBase
+(NSString *) getDbFolderPathWithoutUTF8FromFilePath:(NSString *) fullFilePath andUser:(UserDto *) user {
    
    DLog(@"full file path: %@", fullFilePath);
    NSString *output = @"";
    
    //if the path the receive is: /owncloud/remote.php/webdav/Fotos11/perico2.txt
    //we have to return: Fotos11/
    //if the path the receive is: /owncloud/remote.php/webdav/Fotos11/AA/perico2.txt
    //we have to return: Fotos11/AA/
    
    //1.- Quit the part of the server
    NSUInteger serverLength=[[NSString stringWithFormat:@"%@", k_url_webdav_server]length];
    NSUInteger userUrlLength= [user.url length];
    
    fullFilePath= [fullFilePath substringFromIndex:(serverLength+userUrlLength)];
    
    //2.- Quit the name
    NSArray *splitePath = [fullFilePath componentsSeparatedByString:@"/"];
    
    
    NSString *stringWithoutUTF;
    
    for (int i = 0; i < [splitePath count]; i++) {
        
        if (i != [splitePath count]-1) {
            stringWithoutUTF = [splitePath objectAtIndex:i];
            output = [NSString stringWithFormat:@"%@%@/", output, stringWithoutUTF];
        }
    }
    
    //  DLog(@"output before the substring: %@", output);
    
    //output=[output substringFromIndex:1];
    
    
    return output;
}

//This method return de newfolderpath to find a folder object in DataBase
+(NSString *) getDbFolderPathFromFilePath:(NSString *) filePath {
    NSString *output = @"";
    
    //if filePath is:
    // aa/
    //folder path is:
    //
    //if filePath is:
    // aa/bb/
    //folder path is:
    // aa/
    //if filePath is:
    // aa/bb/cc/
    //folder path is:
    // aa/bb/
    
    NSArray *splitePath = [filePath componentsSeparatedByString:@"/"];
    
    // DLog(@"Splite path of file path is: %d", [splitePath count]);
    
    if ([splitePath count]==2 || [splitePath count]==1 || [splitePath count]==0) {
        output=@"";
    }else if([splitePath count]==3){
        
        output=[NSString stringWithFormat:@"%@/", [splitePath objectAtIndex:0]];
    }else{
        
        for (int i = 0; i < [splitePath count]; i++) {
            
            
            NSString *item=[splitePath objectAtIndex:i];
            
            if ([item isEqualToString:@""]) {
                
            }else{
                if (i==0) {
                    output = [NSString stringWithFormat:@"%@", [splitePath objectAtIndex:i]];
                }
                
                if ((i>0) && (i != [splitePath count]-2)) {
                    
                    output = [NSString stringWithFormat:@"%@/%@", output, [splitePath objectAtIndex:i]];
                }
                
            }
            
        }
        
        //Last character
        unichar last = [output characterAtIndex:[output length] - 1];
        
        if (last=='/') {
            
        }else{
            output = [NSString stringWithFormat:@"%@/", output];
        }
        
        //DLog(@"LastCharacter: %c", last);
    }
    
    
    // DLog(@"output folder path: %@", output);
    
    
    return output;
    
}


//This method return the foldername of new filepah
+(NSString *) getDbFolderNameFromFilePath:(NSString *) filePath {
    NSString *output = @"";

    //if filePath is:
    // aa/
    // folder name is:
    // aa/
    //if filePaht is:
    // aa/bb/
    //folder name is:
    // bb/
    
    NSArray *splitePath = [filePath componentsSeparatedByString:@"/"];
    
   // DLog(@"Splite path of file name is: %d", [splitePath count]);
    
    if ([splitePath count]==2 || [splitePath count]==1 || [splitePath count]==0) {
        output=filePath;
    }else{
        output= [NSString stringWithFormat:@"%@/", [splitePath objectAtIndex:[splitePath count]-2]];
    }
    
    
  //  DLog(@"output folder name: %@", output);
    
    
    return output;
}

+(NSString *) getFilePathOnDBFromFilePathOnFileDto:(NSString *) filePathOnFileDto andUser:(UserDto *) user {
    /*
     /owncloud/remote.php/webdav/
     /remote.php/webdav/
    */
    
    NSString *output = @"";
    
    NSArray *splitedUrl = [user.url componentsSeparatedByString:@"/"];

    for (int i = 3; i < [splitedUrl count] ; i++) {
        output = [NSString stringWithFormat:@"%@/%@", output ,[splitedUrl objectAtIndex:i]];
    }
    
    output = [NSString stringWithFormat:@"%@%@", output, k_url_webdav_server];
    
    //DLog(@"filePathOnFileDto: %@", filePathOnFileDto);
    //DLog(@"DB FilePath to remove: %@", output);
    
    if([filePathOnFileDto length] >= [output length]) {
        output = [filePathOnFileDto substringFromIndex: [output length]];
    }
    
    return  output;
}

+(NSString *) getFilePathByRemoteURL:(NSString *) remoteUrl andUserDto:(UserDto *) mUser {
    
    //remoteUrl: https://beta.owncloud.com/owncloud/remote.php/webdav/Photo-08-04-13-02-33-45-0.PNG
    //FilePath: /owncloud/remote.php/webdav/
    
    NSString *output = @"";
    
    //On uploads with redirections the remoteUrl could be have a different domain as mUser.url
    NSString *remoteUrlWithoutDomain = [self getHttpAndDomainByURL:remoteUrl];
    remoteUrlWithoutDomain = [remoteUrl substringFromIndex:remoteUrlWithoutDomain.length];
    remoteUrl = remoteUrlWithoutDomain;
    
    NSString *userUrlWithoutDomain = [self getHttpAndDomainByURL:mUser.url];
    userUrlWithoutDomain = [mUser.url substringFromIndex:userUrlWithoutDomain.length];
    
    
    NSArray *splitedUrl = [remoteUrl componentsSeparatedByString:@"/"];
    NSString *fileName = [NSString stringWithFormat:@"%@",[splitedUrl objectAtIndex:([splitedUrl count]-1)]];
    
    if ( [remoteUrl length] > [fileName length]) {
        output = [remoteUrl substringToIndex:[remoteUrl length] - [fileName length]];
    }
        
    output = [output substringFromIndex:[userUrlWithoutDomain length] + [k_url_webdav_server length]];
    
    return output;
}

+(NSString *) getRemoteUrlByFile:(FileDto *) file andUserDto:(UserDto *) mUser {
    
    NSString *output = [NSString stringWithFormat:@"%@%@%@",[self getServerURLWithoutFolderByUserDto:mUser],file.filePath,file.fileName];
    
    DLog(@"output: %@", output);
    
    return output;
}

+(NSString *) getServerURLWithoutFolderByUserDto:(UserDto *)mUser {
    
    NSString *output = @"";
    NSArray *userUrlSplited = [mUser.url componentsSeparatedByString:@"/"];
    
    output = [NSString stringWithFormat:@"%@//%@", [userUrlSplited objectAtIndex:0], [userUrlSplited objectAtIndex:2]];
    
    return output;
}

///-----------------------------------
/// @name Pass OCFileDto Array to FileDto Array
///-----------------------------------


+(NSMutableArray*) passToFileDtoArrayThisOCFileDtoArray:(NSArray*)ocFileDtoArray{
    
    NSMutableArray *fileDtoArray = [NSMutableArray new];
    
    //OCFileDto to FileDto
    for (OCFileDto *file in ocFileDtoArray) {
        FileDto *fileDto = [[FileDto alloc]initWithOCFileDto:file];
        [fileDtoArray addObject:fileDto];
    }
    //Free memory
    ocFileDtoArray = nil;

    return fileDtoArray;
}

#pragma mark - Shared DTOs

///-----------------------------------
/// @name Get The Parent Path of the Path
///-----------------------------------

/**
 * Get the parent path of the entire path
 *
 * Example 1: path = /home/music/song.mp3
 *         result = /home/music/
 *
 * @param path -> NSString
 */
+ (NSString*)getTheParentPathOfThePath:(NSString*)path{
    
    NSString *output = @"";
    
    //Example 1: path = /home/music/song.mp3
    //         result = /home/music/
    
    //Example 2: path = /song.mp3
    //          result = /
    
    //Lower case
   // path = [path lowercaseString];
    
     NSArray *splitePath = [path componentsSeparatedByString:@"/"];
    
    //If it's folder remove the last objet because is equal to ""
    if (splitePath.count > 0) {
        NSString *lastString = [splitePath lastObject];
        if ([lastString isEqualToString:@""]) {
            NSMutableArray *copy = [NSMutableArray arrayWithArray:splitePath];
            [copy removeLastObject];
            splitePath = [NSArray arrayWithArray:copy];
        }
        
    }
    
    if (splitePath.count==0) {
        
        output=@"";
        
    } else if (splitePath.count == 1) {
        
        output = @"/";
    } else if (splitePath.count == 2) {
        
        output = @"/";
    } else {
        //First slash
        //output = @"/";
        NSString *word = @"";
        for (int i=0; i<([splitePath count]-1); i++) {
            
            if (i==0) {
                
            } else{
                word = [splitePath objectAtIndex:i];
                output = [NSString stringWithFormat:@"%@/%@", output, word];
            }
        }
        
    }
    
    return output;
    
}

///-----------------------------------
/// @name Get DataBase file_path of fileDto.filePath
///-----------------------------------

/**
 * This method get the real data in the database using the data of the FileDto.
 *
 * Ex: /master/owncloud/remote.php/webdav/music/ --> "music"
 *
 * Ex: /master/owncloud/remote.php/webdav/ --> ""
 *
 * @param path -> NSString
 * 
 * @param user -> UserDto
 *
 * @return NSString
 *

 */
+ (NSString* )getDBFilePathOfFileDtoFilePath:(NSString*)path ofUserDto:(UserDto*)user{
    //if the path the receive is: /master/owncloud/remote.php/webdav/music
    //we have to return: music
    //if the path the receive is: /master/owncloud/remote.php/webdav/
    //we have to return: empty
    
    NSString *removedPart = [UtilsUrls getRemovedPartOfFilePathAnd:user];
    NSUInteger removedPartLength = [removedPart length];
    
    NSString *output = @"";
    
    //Quit removed part
    output= [path substringFromIndex:(removedPartLength)];
    
    DLog(@"filePath: %@", output);
    
    return output;
}


//-----------------------------------
/// @name Get a domain by a URL
///-----------------------------------

/**
 * Method used to get only the domain and the protocol (http/https)
 *
 * @param NSString -> url
 *
 * @return NSString
 *
 */
+ (NSString *) getHttpAndDomainByURL:(NSString *) url {
    
    NSArray *urlSplitted = [url componentsSeparatedByString:@"/"];
    NSString *output = [NSString stringWithFormat:@"%@//%@", [urlSplitted objectAtIndex:0], [urlSplitted objectAtIndex:2]];
    
    return output;
}

@end
