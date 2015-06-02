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




@end
