//
//  UIColor+Constants.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/10/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UIColor+Constants.h"

@implementation UIColor(Constants)

//NAVIGATION AND TOOL BAR

//Tint color of navigation bar
+ (UIColor*)colorOfNavigationBar{
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:1.0];
}
//Color of background view in navigation bar
+ (UIColor*)colorOfBackgroundNavBarImage {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:0.7];
}

//Color of letters in navigation bar
+ (UIColor*)colorOfNavigationTitle{
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0];
}

//Color of items in navigation bar
+ (UIColor*)colorOfNavigationItems{
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0];
}

//Color of background in custom status bar, only for iOS 7 //NOT IN USE
+ (UIColor*)colorOfBackgroundStatusBarNotification {
    return [UIColor colorWithRed:55/255.0f green:70/255.0f blue:89/255.0f alpha:1.0];

}

//Tint color of tool bar
+ (UIColor*)colorOfToolBar{
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:1.0];
}

//Color of background view in toolBar bar, only for iOS 7 for transparency
+ (UIColor*)colorOfBackgroundToolBarImage {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:0.7];

}

//Tint color of tool bar items for detail preview of file view
+ (UIColor*)colorOfToolBarButtons {
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0];
    
}


//TAB BAR

//Tint color of tab bar
+ (UIColor*)colorOfTintUITabBar {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:1.0];
}

//Tint color for selected tab bar item
+ (UIColor*)colorOfTintSelectedUITabBar {
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0];

}

//Tint color for non selected tab bar item (only works with the labels)
+ (UIColor*)colorOfTintNonSelectedUITabBar {
   return [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:1.0];
}


//SETTINGS VIEW

//Text color in some cells of settings view
+ (UIColor*)colorOfDetailTextSettings {
    return [UIColor whiteColor];
}

//Cell background color in some cells of settings view
+(UIColor*)colorOfBackgroundButtonOnList {
    return [UIColor whiteColor];
}

//Text color in some cells of settings view
+(UIColor*)colorOfTextButtonOnList {
    return [UIColor blackColor];
}


//LOGIN VIEW

//Background color of login view
+ (UIColor*)colorOfLoginBackground{
    return [UIColor colorWithRed:245/255.0f green:245/255.0f blue:241/255.0f alpha:1.0];
}

//Text color of url in login view
+ (UIColor*)colorOfURLUserPassword{
    return [UIColor colorWithWhite:0.0 alpha:0.7];
}


//Text color of login text
+ (UIColor*)colorOfLoginText {
    return [UIColor colorWithRed:96/255.0f green:133/255.0f blue:154/255.0f alpha:1.0];
}

//Text color of error credentials
+ (UIColor*)colorOfLoginErrorText{
    return [UIColor colorWithRed:96/255.0f green:133/255.0f blue:154/255.0f alpha:1.0];
}

//Text color of server error //Not in use this color
+ (UIColor*)colorOfServerErrorText{
    return [UIColor colorWithRed:96/255.0f green:133/255.0f blue:154/255.0f alpha:1.0];
}

//Background color of top of login view, in logo image view
+ (UIColor*)colorOfLoginTopBackground {
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1];
}

//Background color of login button
+(UIColor *)colorOfLoginButtonBackground{
    return [UIColor colorWithRed:30/255.0f green:44/255.0f blue:67/255.0f alpha:1.0];
}

//Text color of the text of the login button
+(UIColor *)colorOfLoginButtonTextColor{
    return  [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1];
}


//FILE LIST

//Text color of selected folder
+ (UIColor*)colorOfTxtSelectFolderToolbar {
    return [UIColor whiteColor];
}

//Section index color
+ (UIColor*)colorOfSectionIndexColorFileList {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:0.7];
}

//Header section index color
+ (UIColor*)colorOfHeaderTableSectionFileList {
    return [UIColor colorWithRed:248/255.0f green:248/255.0f blue:248/255.0f alpha:0.85];
}

//WEB VIEW

//Color of webview background
+ (UIColor*)colorOfWebViewBackground{
   return [UIColor colorWithRed:26/255 green:26/255 blue:28/255 alpha:1.0];
}

//Color of background in detail view when there are not file selected
+ (UIColor*)colorOfBackgroundDetailViewiPad{
    return [UIColor whiteColor];
}



@end
