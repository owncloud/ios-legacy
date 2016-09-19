//
//  UtilsBrandedOptions.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 24/05/16.
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

@interface UtilsBrandedOptions : NSObject

+ (NSDictionary *) titleAttributesToNavigationBar;

+ (UILabel *) getCustomLabelForNavBarByName:(NSString *) name;

@end
