//
//  UtilsBrandedOptions.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 24/05/16.
//
//

/*
 Copyright (C) 2016, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsBrandedOptions.h"
#import "UIColor+Constants.h"


@implementation UtilsBrandedOptions

+ (NSDictionary *)titleAttributesToNavigationBar {
    //Set the title color
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:18];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorOfNavigationTitle];
    shadow.shadowOffset = CGSizeMake(0.7, 0);
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [UIColor colorOfNavigationTitle],
                                      NSShadowAttributeName: shadow,
                                      NSFontAttributeName: appFont};
    return titleAttributes;
}

@end
