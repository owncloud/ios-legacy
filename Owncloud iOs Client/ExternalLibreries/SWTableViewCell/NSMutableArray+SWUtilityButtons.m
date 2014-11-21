//
//  NSMutableArray+SWUtilityButtons.m
//  SWTableViewCell
//
//  Created by Matt Bowman on 11/27/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import "NSMutableArray+SWUtilityButtons.h"

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
 * Method to add a field on swipe with two lines of text. Used on the Shared table view
 *
 * @param UIColor -> color of background
 * @param NSString -> title of the field
 *
 */
- (void)sw_addUtilityOneLineButtonWithColor:(UIColor *)color title:(NSString *)title andImage:(UIImage *) image
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = color;
    
    [self addObject:button];
    
    //Custom image
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [imageView setFrame:CGRectMake(20, 10, 25, 25)];

    
    //Custom label
    //The cell is 90 x 60
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(8, 20, 50, 50)];
    titleLabel.numberOfLines = 1;
    [titleLabel setFont:[UIFont fontWithName:@"Arial" size:11.0f]];
    [titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = title;
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [button addSubview:imageView];
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

