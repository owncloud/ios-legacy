//
//  UtilsCookies.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/07/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import <Foundation/Foundation.h>

@class UserDto;

@interface UtilsCookies : NSObject

+ (void) setOnDBStorageCookiesByUser:(UserDto *) user;
+ (void) setOnSystemStorageCookiesByUser:(UserDto *) user;

+ (void) eraseCredentialsWithURL:(NSString *)connectURL;
+ (void) eraseURLCache;
+ (void) eraseCredentialsAndUrlCacheOfActiveUser;

@end
