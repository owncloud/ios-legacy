//
//  OCNavigationController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 13/09/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import <UIKit/UIKit.h>
#import "PassthroughView.h"


@interface OCNavigationController : UINavigationController{
    
    PassthroughView *_backgroundView;
}

///-----------------------------------
/// @name Manage Background View
///-----------------------------------

/**
 * This method add or hide the background view into nav bar
 *
 * @param isShow -> Indicate if the nav bar is show or not
 */
- (void)manageBackgroundView:(BOOL)isShow;


@end
