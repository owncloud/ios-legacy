//
//  UtilsLogin.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 18/07/2017.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsLogin.h"

#ifdef CONTAINER_APP
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif

@implementation UtilsLogin

+ (UniversalLoginViewController *)getLoginVCWithMode:(LoginMode)loginMode andUser:(UserDto *)user {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UniversalLoginViewController *universalLoginVC = (UniversalLoginViewController*)[storyboard instantiateViewControllerWithIdentifier:@"universalLoginViewController"];
    [universalLoginVC setLoginModeWithLoginMode:loginMode user:user];
    //[];
     
    return universalLoginVC;
}

@end
