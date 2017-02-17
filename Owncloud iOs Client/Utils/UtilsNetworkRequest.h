//
//  UtilsNetworkRequest.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/10/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "UserDto.h"

typedef enum {
    isNotInThePath = 0,
    isInThePath = 1,
    errorSSL = 2,
    credentialsError = 3,
    serverConnectionError = 4
} enumTheFileIsInThePathResponse;

@protocol UtilsNetworkRequestDelegate
- (void) theFileIsInThePathResponse:(NSInteger) response;
@end


@interface UtilsNetworkRequest : NSObject

@property(nonatomic,strong) id<UtilsNetworkRequestDelegate> delegate;

- (void)checkIfTheFileExistsWithThisPath:(NSString*)path andUser:(UserDto *) user;

+ (NSMutableDictionary *) getHttpLoginHeaders;

@end
