//
//  ImageUtils.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 09/10/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ImageUtils.h"

@implementation ImageUtils

///-----------------------------------
/// @name Image With Color
///-----------------------------------

/**
 * This method receive a color and return a image based in this color
 *
 * @param color -> UIColor
 *
 * @return UIImage
 *
 */
+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (NSString *)getTheNameOfTheBrandImage {

    NSString *imageName;

    //Default name
    imageName = @"BackRootFolderIcon";
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    //The special icon for chritmats only for ownCloud app
    if ([appName isEqualToString:@"ownCloud"]) {
        // After day 354 of the year, the usual ownCloud icon is replaced by another icon
        NSCalendar *gregorian =
        [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:[NSDate date]];
        if (dayOfYear >= 354)
            imageName = @"ownCloud-xmas";

    }

    return imageName;
}

+ (UIImage *)getNavigationLogoImage {

    UIImage *logoImage = [UIImage imageNamed:[self getTheNameOfTheBrandImage]];
    logoImage = [logoImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    return logoImage;
}

@end
