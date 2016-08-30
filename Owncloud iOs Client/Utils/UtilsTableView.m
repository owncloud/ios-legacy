//
//  UtilsTableView.m
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

#import "UtilsTableView.h"

@implementation UtilsTableView

#define k_status_bar_height 20
#define k_tableViewHeight_portrait 932
#define k_tableViewHeight_landscape 748
#define k_tableViewHeight_portrait_ios6 831
#define k_tableViewHeight_landscape_ios6 655

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
+ (CGFloat) getUITableViewHeightForSingleRowByNavigationBatHeight:(CGFloat) navigationBarHeight andTabBarControllerHeight:(CGFloat) tabBarControllerHeight andTableViewHeight:(CGFloat) tableViewHeightForIphone {
    
    CGFloat height = 0.0;
    
    //Obtain the center of the table
    CGFloat tableViewHeight = 0.0;
    if (!IS_IPHONE) {
        
        if (IS_PORTRAIT) {
            tableViewHeight = k_tableViewHeight_portrait;
        } else {
            tableViewHeight = k_tableViewHeight_landscape;
        }
        
        height = tableViewHeight - tabBarControllerHeight - navigationBarHeight;
        
    } else {
        tableViewHeight = tableViewHeightForIphone;
        
        if (IS_IOS7) {
            height = tableViewHeight- tabBarControllerHeight - navigationBarHeight - k_status_bar_height;
        }else{
            
            if (IS_PORTRAIT) {
                 height = tableViewHeight- tabBarControllerHeight - navigationBarHeight - k_status_bar_height;
            }else{
                height = tableViewHeight- tabBarControllerHeight - navigationBarHeight;
            }
        }
    }
    
    return height;
}

@end
