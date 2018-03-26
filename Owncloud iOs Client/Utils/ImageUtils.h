//
//  ImageUtils.h
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

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject

/**
 * This method receive a color and return a image based in this color
 *
 * @param color -> UIColor
 *
 * @return UIImage
 *
 */
+ (UIImage *)imageWithColor:(UIColor *)color;


///-----------------------------------
/// @name Get the Name of the Brand Image
///-----------------------------------
/**
 * This method return a string with the name of the brand image
 * Used by ownCloud and other brands
 *
 * If the day of the year is 354 or more the string return is an
 * especial image for Christmas day.
 *
 * @return image name -> NSString
 */
+ (NSString *)getTheNameOfTheBrandImage;

///-----------------------------------
/// @name Get Logo Image to use in the navigation bar
///-----------------------------------
/**
 * This method return an image with the rendering mode AlwaysOriginal
 *
 * @return image -> UIIMAGE
 */
+ (UIImage *)getNavigationLogoImage;

@end
