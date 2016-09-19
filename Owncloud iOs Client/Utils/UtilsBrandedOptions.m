//
//  UtilsBrandedOptions.m
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

#import "UtilsBrandedOptions.h"
#import "UIColor+Constants.h"


@implementation UtilsBrandedOptions

+ (NSDictionary *)titleAttributesToNavigationBar {
    //Set the title color
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorOfNavigationTitle];
    shadow.shadowOffset = CGSizeMake(0.7, 0);
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [UIColor colorOfNavigationTitle],
                                      NSShadowAttributeName: shadow,
                                      NSFontAttributeName: appFont};
    return titleAttributes;
}


/*
 * Method that put a custom title label in navBar with truncate middle.
 */
+ (UILabel *) getCustomLabelForNavBarByName:(NSString *) name {
    DLog(@"Put the title of the file in the navigation bar");

    UILabel *customLabel = [[UILabel alloc]initWithFrame: CGRectMake(0, 0, 270, 44)];
    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    
    [customLabel setBackgroundColor:[UIColor clearColor]];
    [customLabel setTextColor:[UIColor colorOfNavigationTitle]];
    
    [customLabel setFont:titleFont];
    [customLabel setShadowColor:[UIColor colorOfNavigationTitle]];
    [customLabel setShadowOffset:CGSizeMake(0.7, 0)];
    
    [customLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [customLabel setTextAlignment:NSTextAlignmentCenter];
    [customLabel setClipsToBounds:YES];
    
    customLabel.text = [name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return customLabel;
}


@end
