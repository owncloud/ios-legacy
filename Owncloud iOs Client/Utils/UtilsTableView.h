//
//  UtilsTableView.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 30/04/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@interface UtilsTableView : NSObject

//-----------------------------------
/// @name getUITableViewHeightForSingleRowByNavigationBatHeight
///-----------------------------------

/**
 * Method to return the height of the UITableView to draw a cell with the exact size
 *
 * @param CGFloat -> navigationBarHeight
 * @param CGFloat -> tabBarControllerHeight
 * @param CGFloat -> tableViewHeightForIphone
 *
 * @return CGFloat
 */
+ (CGFloat) getUITableViewHeightForSingleRowByNavigationBatHeight:(CGFloat) navigationBarHeight andTabBarControllerHeight:(CGFloat) tabBarControllerHeight andTableViewHeight:(CGFloat) tableViewHeightForIphone;

@end
