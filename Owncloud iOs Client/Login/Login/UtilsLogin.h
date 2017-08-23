//
//  UtilsLogin.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 18/07/2017.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "UserDto.h"


@class UniversalLoginViewController;

typedef NS_ENUM (NSUInteger, LoginMode){
    LoginModeCreate,
    LoginModeUpdate,
    LoginModeExpire,
    LoginModeMigrate,
};

@interface UtilsLogin : NSObject


+ (UniversalLoginViewController *)getLoginVCWithMode:(LoginMode)loginMode andUser:(UserDto *)user;

@end
