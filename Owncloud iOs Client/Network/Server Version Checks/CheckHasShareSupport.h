//
//  CheckHasShareSuppoer.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 05/08/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@interface CheckHasShareSupport : NSObject

///-----------------------------------
/// @name Check if server has share support
///-----------------------------------

/**
 * This method check the current server looking for support Share API
 * and store (YES/NOT) in the global variable.
 *
 */
- (void)checkIfServerHasShareSupport;

///-----------------------------------
/// @name updateSharesFromServer
///-----------------------------------

/**
 * Method that force to check the shares files and folders
 *
 */

- (void) updateSharesFromServer;

@end
