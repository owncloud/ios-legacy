//
//  CheckCapabilities.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 3/11/15.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

extern NSString * CapabilitiesUpdatedNotification;


@interface CheckCapabilities : NSObject

+ (void) getServerCapabilitiesOfActiveAccount:(void(^)(OCCapabilities *capabilities))success failure:(void(^)(NSError *error))failure;
+ (void) updateServerCapabilitiesOfActiveAccountInDB:(OCCapabilities *)capabilities;
+ (void) reloadFileList;

@end
