//
//  DetectUserData.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 18/10/2017.
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

@interface DetectUserData : NSObject

+ (void) getUserDisplayNameOfServer:(NSString*)path credentials:(OCCredentialsDto *)credentials
                     withCompletion:(void(^)(NSString *serverUserID, NSString *displayName, NSError *error))completion;

@end
