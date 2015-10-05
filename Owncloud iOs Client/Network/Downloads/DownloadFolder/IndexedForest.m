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

- (void) addFileToTheForest:(FileDto*) file {
    
    NSString *key = [UtilsUrls getKeyByLocalFolder:file.localFolder];
    NSArray *keyDivided = [key componentsSeparatedByString:@"/"];
    NSString *keyConstructed = @"";
    
    CWLOrderedDictionary *tmpTreeDictionary = self.treeDictionary;
    
    //Every keyDivided is a diferent level of the tree
    for (NSString *current in keyDivided) {
        
        keyConstructed = [keyConstructed stringByAppendingString:current];
    
        //Check if is one of the parts of the structure of the file Ex: /Documents/Folder/
        if (keyConstructed.length < key.length) {
            keyConstructed = [keyConstructed stringByAppendingString:@"/"];
            
            CWLOrderedDictionary *tempFakeDictFolder = [tmpTreeDictionary objectForKeyedSubscript:keyConstructed];
            
            //If not exist we have to get it from the DB to have all the tree in memory
            if (!tempFakeDictFolder) {
                tempFakeDictFolder = [CWLOrderedDictionary new];
                [tmpTreeDictionary setObject:tempFakeDictFolder forKey:keyConstructed];
            }
        }
    }
    
    self.treeDictionary = tmpTreeDictionary;
    
    //Now we have the tree constructed
    //Is the file so this is the last level of the tree
    CWLOrderedDictionary *tempFakeDictFolder = [tmpTreeDictionary objectForKeyedSubscript:keyConstructed];
    [tempFakeDictFolder setObject:file forKey:keyConstructed];

}

@end
