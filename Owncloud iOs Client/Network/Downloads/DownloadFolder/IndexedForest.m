//
//  IndexedForest.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 02/10/15.
//
//

#import "IndexedForest.h"
#import "UtilsUrls.h"
#import "FolderSyncDto.h"
#import "ManageFilesDB.h"

@implementation IndexedForest

- (id) init{
    
    self = [super init];
    if (self) {
        self.treeDictionary = [CWLOrderedDictionary new];
    }
    return self;
}

- (void) addFileToTheForest:(FileDto *) file {
    
    NSString *key = [UtilsUrls getKeyByLocalFolder:file.localFolder];
    NSArray *keyDivided = [key componentsSeparatedByString:@"/"];
    NSString *keyConstructed = @"";
    
    CWLOrderedDictionary *structuredDict = self.treeDictionary;
    
    //Every keyDivided is a diferent level of the tree
    for (NSString *current in keyDivided) {
        
        keyConstructed = [keyConstructed stringByAppendingString:current];
        
        if (keyConstructed.length < key.length) {
            keyConstructed = [keyConstructed stringByAppendingString:@"/"];
            
            CWLOrderedDictionary *tmpDict = [structuredDict objectForKey:keyConstructed];
            
            if (!tmpDict) {
                //Not exist so we create a new one
                tmpDict = [CWLOrderedDictionary new];
                [structuredDict setObject:tmpDict forKey:keyConstructed];
            }
            
            structuredDict = [structuredDict objectForKey:keyConstructed];
            
        } else {
            //Is the file
            [structuredDict setObject:file forKey:keyConstructed];
        }
    }
}

- (void) removeFileFromTheForest:(FileDto *) file {
    
    NSString *key = [UtilsUrls getKeyByLocalFolder:file.localFolder];
    NSArray *keyDivided = [key componentsSeparatedByString:@"/"];
    NSString *keyConstructed = @"";
    
    CWLOrderedDictionary *structuredDict = self.treeDictionary;
    
    //Every keyDivided is a diferent level of the tree
    for (NSString *current in keyDivided) {
        
        keyConstructed = [keyConstructed stringByAppendingString:current];
        
        if (keyConstructed.length < key.length) {
            
            keyConstructed = [keyConstructed stringByAppendingString:@"/"];
            structuredDict = [structuredDict objectForKey:keyConstructed];
            
        } else {
            //Is the file
            [structuredDict removeObjectForKey:keyConstructed];
        }
    }
    
    DLog(@"File removed from the tree");
}

@end
