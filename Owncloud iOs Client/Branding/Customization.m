//
//  Customization.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 03/07/2017.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "Customization.h"

@implementation Customization

//Add all boolean constants to use in swift classes

+(BOOL)kHideUrlServer {
    return k_hide_url_server;
}

+(BOOL)kForceUpdateOfServerUrl {
    return k_force_update_of_server_url;
}

+(BOOL)kIsSsoActive {
    return k_is_sso_active;
}

+(BOOL)kIsTextLoginStatusBarWhite {
    return k_is_text_login_status_bar_white;
}

+(BOOL)kIsShownHelpLinkOnLogin {
    return k_is_shown_help_link_on_login;
}


@end

