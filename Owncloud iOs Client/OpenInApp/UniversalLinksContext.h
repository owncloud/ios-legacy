//
//  UniversalLinksContext.h
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 14/02/2018.
//

#import <Foundation/Foundation.h>

@protocol UniversalLinksStrategy <NSObject>

@required
-(void)handleLink: (void(^)(NSArray *items))success failure:(void(^)(NSError *)) failure;

@end

@interface UniversalLinksContext : NSObject
{
    __unsafe_unretained id<UniversalLinksStrategy> strategy;
}

@property (assign) id<UniversalLinksStrategy> strategy;


///*!
// *  @brief This method handles the whole process of dealing with the universal links.
// *  @discussion From requesting the redirected link to handle the process of getting all the files inside the folder
// *  and managing the possible errors if they existed.
// *
// *  It asks for the redirection of the private link and get a sorted sequence of FileDTO from the Root forlder to the
// *  file or folder desired (Which is represented by the private link).
// *
// *  For example if you have the private link url like @a https://server.com/f/12
// *  After you ask for the redirection of this link you now have @a https://server.com/remote.php/webdav/Documents/Photos
// *  So the items to return would look like:
// *
// *  @code
// *  +---------+-----------+---------+
// *  | FileDTO |  FileDTO  | FileDTO |
// *  +---------+-----------+---------+
// *  | Root    | Documents | Photos  |
// *  +---------+-----------+---------+
// *  @endcode
// *
// *  @param success A sorted sequence of FileDTO from Root to the folder or file tapped in the link.
// *  @param failure Error in the workflow.
// */
-(void)handleLink: (void(^)(NSArray *items))success failure:(void(^)(NSError *)) failure;

@end
