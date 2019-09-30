//
//  UIImage+UIImage_Device.m
//  Owncloud iOs Client
//
//  Created by Matthias Hühne on 28.06.19.
//

/*
 Copyright (C) 2019, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UIImage+Device.h"

@implementation UIImage (Device)

+ (CGFloat)deviceHeight {
	return [[UIScreen mainScreen] bounds].size.height;
}

+ (UIImage *)deviceImageNamed:(NSString *)imageName {
	NSString *deviceName = [NSString stringWithFormat:@"%@-%d", imageName, (int)[self deviceHeight]];

	if( [self imageNamed:deviceName] != nil) {
		return [self imageNamed:deviceName];
	}

	return [self imageNamed:imageName];
}

@end
