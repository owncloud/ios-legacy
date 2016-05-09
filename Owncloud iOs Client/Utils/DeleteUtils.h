//
//  DeleteUtils.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 09/05/16.
//
//

#import <Foundation/Foundation.h>

@interface DeleteUtils : NSObject

/*
 *  Method to delete all the files that can be deleted by user
 */
+ (void) deleteAllDownloadedFilesByUser:(UserDto *) user;

@end
