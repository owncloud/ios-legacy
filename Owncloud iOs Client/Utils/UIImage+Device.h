//
//  UIImage+UIImage_Device.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Device)

+ (UIImage *)deviceImageNamed:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
