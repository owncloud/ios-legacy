//
//  IndexedForest.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 02/10/15.
//
//

#import "CWLOrderedDictionary.h"
@class FileDto;

@interface IndexedForest : NSObject

@property (nonatomic, strong) CWLOrderedDictionary *treeDictionary;

- (void) addFileToTheForest:(FileDto*) file;
- (void) removeFileFromTheForest:(FileDto *) file ;
- (CWLOrderedDictionary *) getDictionaryOfTreebyKey:(NSString *) key;


@end
