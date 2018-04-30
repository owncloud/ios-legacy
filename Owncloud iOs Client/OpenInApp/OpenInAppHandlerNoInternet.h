//
//  OpenInAppHandlerNoInternet.h
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 13/02/2018.
//

#import <Foundation/Foundation.h>
#import "UniversalLinksContext.h"
@interface OpenInAppHandlerNoInternet : NSObject <UniversalLinksStrategy>

/*!
 *  Link that the user taps in third party app.
 */
@property  (readonly) NSURL *tappedLinkURL;

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
