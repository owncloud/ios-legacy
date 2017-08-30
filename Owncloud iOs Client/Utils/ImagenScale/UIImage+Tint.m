//
//  UIImage+Tint.m
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 30/08/2017.
//
//

#import "UIImage+Tint.h"

@implementation UIImage (Tint)
- (UIImage *)tintedImageWithColor:(UIColor *)tintColor {
    // It's important to pass in 0.0f to this function to draw the image to the scale of the screen
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0];
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}
@end
