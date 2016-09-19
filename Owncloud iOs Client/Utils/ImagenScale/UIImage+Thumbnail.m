//
//  UIImage+Thumbnail.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/12/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "UIImage+Thumbnail.h"


#define kThumbnailWidth 128.0
#define kThumbnailHeight 128.0

@implementation UIImage (Thumbnail)

- (UIImage *) getThumbnailFromDownloadedImage{
    
    return [self imageScaledToFillSize:CGSizeMake(kThumbnailWidth, kThumbnailHeight)];
}

- (UIImage *) imageScaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/self.size.width, size.height/self.size.height);
    CGFloat width = self.size.width * scale;
    CGFloat height = self.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawInRect:imageRect];
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultingImage;
}

@end
