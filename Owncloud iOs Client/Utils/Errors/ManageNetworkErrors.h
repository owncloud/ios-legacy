//
//  ManageNetworkErrors.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 26/06/14.
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

@protocol ManageNetworkErrorsDelegate

@optional
- (void)errorLogin;
- (void)showError:(NSString *) message;
@end

@interface ManageNetworkErrors : NSObject

@property(nonatomic,strong) id<ManageNetworkErrorsDelegate> delegate;

/*
 * Method called when receive an error from server
 * @errorHttp -> WebDav Server Error of NSURLResponse
 * @errorConnection -> NSError of NSURLSession
 * @user -> UserDto
 */

- (void)manageErrorHttp:(NSInteger)errorHttp andErrorConnection:(NSError *)errorConnection andUser:(UserDto *)user;
- (void)returnErrorMessageWithHttpStatusCode:(NSInteger) errorHttp andError:(NSError *) error;


@end
