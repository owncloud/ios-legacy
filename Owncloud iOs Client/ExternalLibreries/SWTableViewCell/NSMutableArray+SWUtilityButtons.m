//
//  NSMutableArray+SWUtilityButtons.m
//  SWTableViewCell
//
//  Created by Matt Bowman on 11/27/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import "NSMutableArray+SWUtilityButtons.h"

#define k_swipe_width_cell 175.0
#define k_witdh_labels 50.0
#define k_height_labels 50.0
#define k_origin_y_labels 20.0


@implementation NSMutableArray (SWUtilityButtons)

- (void)sw_addUtilityButtonWithColor:(UIColor *)color title:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = color;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    
    [self addObject:button];
    
}


///-----------------------------------
/// @name sw_addUtilityTwoLinesButtonWithColor
///-----------------------------------

/**
 * Method to add a field on swipe with two lines of text. Used on the Shared table view
 *
 * @param UIColor -> color of background
 * @param NSString -> title of the field
 *
 */
- (void)sw_addUtilityTwoLinesButtonWithColor:(UIColor *)color title:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = color;
    
    [self addObject:button];
    
    //Custom label
    //The cell is 90 x 60
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 5, 80, 50)];
    titleLabel.numberOfLines = 2;
    [titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = title;
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [button addSubview:titleLabel];
}

///-----------------------------------
/// @name sw_addUtilityTwoLinesButtonWithColor
///-----------------------------------

/**
 * Method to add a field on swipe with one line of text behind the icon. Used on the Shared table view
 *
 * @param UIColor -> color of background
 * @param NSString -> title of the field
 * @param areOnlyTwoButtons -> YES/NO (Yes -> two buttons. Np -> Three buttons)
 *
 */
- (void)sw_addUtilityOneLineButtonWithColor:(UIColor *)color title:(NSString *)title andImage:(UIImage *) image forTwoButtons:(BOOL) areOnlyTwoButtons
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = color;
    [button setImage:image forState:UIControlStateNormal];

    
    [self addObject:button];
    
    CGRect labelFrame;
    
    if (areOnlyTwoButtons) {
        //Two buttons
        labelFrame = CGRectMake((((k_swipe_width_cell / 2) - k_witdh_labels) / 2), k_origin_y_labels, k_witdh_labels, k_height_labels);
        
    }else{
       //Three buttons
        labelFrame = CGRectMake(((k_swipe_width_cell / 3) - k_witdh_labels), k_origin_y_labels, k_witdh_labels, k_height_labels);
        
    }
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:labelFrame];
    
    titleLabel.numberOfLines = 1;
    [titleLabel setFont:[UIFont fontWithName:@"Arial" size:11.0f]];
    [titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = title;
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [button addSubview:titleLabel];
    
    
}

- (void)sw_addUtilityButtonWithColor:(UIColor *)color icon:(UIImage *)icon
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = color;
    [button setImage:icon forState:UIControlStateNormal];
    [self addObject:button];
}

@end

