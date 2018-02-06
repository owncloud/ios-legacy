//  Copyright (C) 2018, ownCloud GmbH.
//  This code is covered by the GNU Public License Version 3.
//  For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
//  You should have received a copy of this license along with this program.
//  If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
//
//  @Authors
//      Pablo Carrascal.


#import <Foundation/Foundation.h>

/*!
 *  @brief Instances of OpenInAppHandler create a handler to deal with all the process of open the app from a external
 *  univeral Link.
 *
 *  @discussion This is mainly achieved by calling the function @b handleLink:failure:
 *
 *  @warning This class doesn't open the files view with a selected FileDTO.
 */
@interface OpenInAppHandler : NSObject

/*!
 *  Link that the user taps in third party app.
 */
@property  (readonly) NSURL *tappedLinkURL;

/*!
 *  Link after redirection of the tappedLinkURL.
 */
@property  NSURL *finalURL;

/*!
 *  Current active user in the app.
 */
@property  UserDto *user;

/*!
 *  @brief Init the handler with a url and a user.
 *
 *  @param linkURL Private link clicked by the user in a third party app.
 *  @param user Current user of the app.
 *
 *  @return A new OpenInAppHandler object with the url and user passed by parameter.
 *
 *  @pre The private link should be in the following scheme @a https://server/f/id ,
 *  for example @a https://owncloud.com/f/13
 */
-(id)initWithLink:(NSURL *)linkURL andUser:(UserDto *) user;

/*!
 *  @brief This method handles the whole process of dealing with the universal links.
 *  @discussion From requesting the redirected link to handle the process of getting all the files inside the folder
 *  and managing the possible errors if they existed.
 *
 *  It asks for the redirection of the private link and get a sorted sequence of FileDTO from the Root forlder to the
 *  file or folder desired (Which is represented by the private link).
 *
 *  For example if you have the private link url like @a https://server.com/f/12
 *  After you ask for the redirection of this link you now have @a https://server.com/remote.php/webdav/Documents/Photos
 *  So the items to return would look like:
 *
 *  @code
 *  +---------+-----------+---------+
 *  | FileDTO |  FileDTO  | FileDTO |
 *  +---------+-----------+---------+
 *  | Root    | Documents | Photos  |
 *  +---------+-----------+---------+
 *  @endcode
 *
 *  @param success A sorted sequence of FileDTO from Root to the folder or file tapped in the link.
 *  @param failure Error in the workflow.
 */
-(void)handleLink: (void(^)(NSArray *items))success failure:(void(^)(NSError *error)) failure;

-(void)handleLink1: (void(^)(FileDto *item))success failure:(void(^)(NSError *error))failure;


@end
