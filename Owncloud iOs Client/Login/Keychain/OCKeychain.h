//
//  OCKeychain.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 22/10/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "CredentialsDto.h"

@interface OCKeychain : NSObject

+(BOOL)setCredentialsById:(NSString *)idUser withUsername:(NSString *)userName andPassword:(NSString *)password;
+(CredentialsDto *)getCredentialsById:(NSString *)idUser;
+(BOOL)removeCredentialsById:(NSString *)idUser;
+(BOOL)updateCredentialsById:(NSString *)idUser withUsername:(NSString *)userName andPassword:(NSString *)password;
+(BOOL)updateKeychainForUseLockPropertyForUser:(NSString *)idUser;
+(BOOL)resetKeychain;
+(void)updateAllKeychainsToUseTheLockProperty;

@end
