//
//  IndexedForest.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 02/10/15.
//
//

#import "CWLOrderedDictionary.h"
@class FileDto;

@interface IndexedForest : CWLOrderedDictionary

- (void) addFileToTheForest:(FileDto*) file;

@end
