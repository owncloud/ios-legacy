//  Copyright (C) 2018, ownCloud GmbH.
//  This code is covered by the GNU Public License Version 3.
//  For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
//  You should have received a copy of this license along with this program.
//  If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
//
//  @Authors
//      Pablo Carrascal.


#import <Foundation/Foundation.h>
#import "UniversalLinksContext.h"
/*!
 *  @brief Instances of OpenInAppHandler create a handler to deal with all the process of open the app from a external
 *  univeral Link.
 *
 *  @discussion This is mainly achieved by calling the function @b handleLink:failure:
 *
 *  @warning This class doesn't open the files view with a selected FileDTO.
 */
@interface OpenInAppHandler : NSObject <UniversalLinksStrategy>

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


@end
