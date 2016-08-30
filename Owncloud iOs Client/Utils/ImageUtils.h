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

@end
