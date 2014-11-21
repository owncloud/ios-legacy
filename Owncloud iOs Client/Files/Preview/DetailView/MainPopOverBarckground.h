//
//  MainPopOverBarckground.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 19/09/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>

@interface MainPopOverBarckground : UIPopoverBackgroundView{
    
    UIImageView *_imageView;
    
    UIImageView *_arrowView;
}

@property (nonatomic, readwrite) CGFloat arrowOffset;
@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;


+ (CGFloat)arrowHeight;

+ (CGFloat)arrowBase;

+ (UIEdgeInsets)contentViewInsets;


@end
