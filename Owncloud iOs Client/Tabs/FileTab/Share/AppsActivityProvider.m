//
//  ShareLinkActivityProvider.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 1/14/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "AppsActivityProvider.h"
#import "NSString+Encoding.h"

///-----------------------------------
/// @name APCopyActivityIcon
///-----------------------------------

/**
 * Implementation of the class APCopyActivityIcon to support copy the link
 *
 */
@implementation APCopyActivityIcon

///-----------------------------------
/// @name initWithLink
///-----------------------------------

/**
 * Method to init the Activity addin the link
 *
 * @param NSString -> Link of the shared file
 */
- (id)initWithLink:(NSString *)sharedLink {
    if (self = [super init]) {
        _sharedLink = sharedLink;
    }
    return self;
}

///-----------------------------------
/// @name isAppInstalled
///-----------------------------------

/**
 * Method to return if this app is installed on the device
 *
 */
- (BOOL) isAppInstalled {
    return YES;
}

- (NSString *)activityType {
    return @"";
}

///-----------------------------------
/// @name activityTitle
///-----------------------------------

/**
 * Method to return the text under de icon
 *
 */
- (NSString *)activityTitle {
    return NSLocalizedString(@"copy_link", nil);
}

///-----------------------------------
/// @name activityImage
///-----------------------------------

/**
 * Method to retun the icon of the activiy
 *
 */
- (UIImage *) activityImage {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [UIImage imageNamed:@"CopyLinkShareipad.png"];
    } else {
        return [UIImage imageNamed:@"CopyLinkShareiphone.png"];
    }
}
- (BOOL) canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}
- (void) prepareWithActivityItems:(NSArray *)activityItems {
}
- (UIViewController *) activityViewController {
    return nil;
}

///-----------------------------------
/// @name performActivity
///-----------------------------------

/**
 * Method to do the things once the user click over the icon
 *
 * @warning Do not add at the end [self activityDidFinish:YES]; because if not the Share view does not dissaper
 */
- (void) performActivity {
    
    DLog(@"_sharedLink: %@", _sharedLink);
    
    //Copy link to pasteboard
    NSString *copyStringverse = _sharedLink;
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:copyStringverse];
    
    [self activityDidFinish:YES];
}

@end

///-----------------------------------
/// @name APWhatsAppActivityIcon
///-----------------------------------

/**
 * Implementation of the class APWhatsAppActivityIcon to support whatsapp
 *
 */
@implementation APWhatsAppActivityIcon

/**
 * Method to init the Activity addin the link
 *
 * @param NSString -> Link of the shared file
 */
- (id)initWithLink:(NSString *)sharedLink {
    if (self = [super init]) {
        _sharedLink = sharedLink;
    }
    return self;
}

///-----------------------------------
/// @name isAppInstalled
///-----------------------------------

/**
 * Method to return if this app is installed on the device
 *
 */
- (BOOL) isAppInstalled {
    
    BOOL output = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://"]];
    
    return output;
}

- (NSString *)activityType {
    return @"net.whatsapp.WhatsApp";
}

///-----------------------------------
/// @name activityTitle
///-----------------------------------

/**
 * Method to return the text under de icon
 *
 */
- (NSString *)activityTitle {
    return @"WhatsApp";
}

///-----------------------------------
/// @name activityImage
///-----------------------------------

/**
 * Method to retun the icon of the activiy
 *
 */
- (UIImage *) activityImage {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [UIImage imageNamed:@"WhatsappShareipad.png"];
    } else {
        return [UIImage imageNamed:@"WhatsappShareiphone.png"];
    }
}

- (BOOL) canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}
- (void) prepareWithActivityItems:(NSArray *)activityItems {
}
- (UIViewController *) activityViewController {
    return nil;
}

///-----------------------------------
/// @name performActivity
///-----------------------------------

/**
 * Method to do the things once the user click over the icon
 *
 * @warning Do not add at the end [self activityDidFinish:YES]; because if not the Share view does not dissaper
 */
- (void) performActivity {
    
    DLog(@"_sharedLink: %@", _sharedLink);
    
    _sharedLink = [_sharedLink encodeString:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"whatsapp://send?text=" stringByAppendingString:_sharedLink]]];
    
    [self activityDidFinish:YES];
}

@end
