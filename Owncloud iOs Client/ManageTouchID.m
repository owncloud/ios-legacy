//
//  ManageTouchID.m
//  Owncloud iOs Client
//
//  Created by María Rodríguez on 20/01/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <LocalAuthentication/LocalAuthentication.h>
#import "ManageTouchID.h"

@implementation ManageTouchID
@synthesize delegate;


+ (ManageTouchID *)sharedSingleton {
    static ManageTouchID *sharedSingleton;
    @synchronized(self)
    {
        if (!sharedSingleton){
            sharedSingleton = [[ManageTouchID alloc] init];
        }
        return sharedSingleton;
    }
}

- (BOOL)isTouchIDAvailable {
    
    NSError *error = nil;
    if([[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]){
        return true;
    }
    else{
        DLog(@"touchID not available: %@", error.description);
        return false;
    }
}

/* Use isTouchIDAvailable before */
- (void)showTouchIDAuth {
    if (self.isTouchIDAvailable) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        [[[LAContext alloc] init] evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason: [NSLocalizedString(@"unlock_app", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName] reply:^(BOOL success, NSError * error){
            
            if(error) {
                NSString *failureReason;
                //depending on error show what exactly has failed
                switch (error.code) {
                        
                        // Authentication was not successful, because user failed to provide valid credentials.
                    case LAErrorAuthenticationFailed:
                        failureReason = @"Touch ID authentication failed because user failed to provide valid credentials";
                        break;
                        
                        // Authentication was canceled by user (e.g. tapped Cancel button).
                    case LAErrorUserCancel:
                        failureReason = @"Touch ID authentication cancelled";
                        break;
                        
                        // Authentication was canceled, because the user tapped the fallback button (Enter Password)
                    case LAErrorUserFallback:
                        failureReason =  @"Touch ID authentication choose password selected";
                        break;
                        
                        // Authentication was canceled by system (e.g. another application went to foreground).
                    case LAErrorSystemCancel:
                        failureReason =  @"Touch ID authentication was canceled by system";
                        break;
                        
                        // Authentication could not start, because passcode is not set on the device.
                    case LAErrorPasscodeNotSet:
                        failureReason =  @"Touch ID authentication failed because passcode is not set on the device";
                        break;
                        
                        // Authentication could not start, because Touch ID is not available on the device.
                    case LAErrorTouchIDNotAvailable:
                        failureReason =  @"Touch ID authentication is not available on the device";
                        break;
                        
                        // Authentication could not start, because Touch ID has no enrolled fingers.
                    case LAErrorTouchIDNotEnrolled:
                        failureReason =  @"Touch ID authentication failed because has no enrolled fingers";
                        break;
                        
                    default:
                        failureReason = (error.code == -1000)? @"Touch ID time out":@"Touch ID unknown error";
                        break;
                }
                
                DLog(@"Authentication failed: %@", failureReason);
                
                
            }
            if(success) {
                DLog(@"Successfully Touch ID authenticated");
                [self.delegate didBiometricAuthenticationSucceed];
                
            }
            
            else{
                DLog(@"Touch ID. The finger print doesn't match");
            }
        }];
        
    } else {
        DLog(@"Your device cannot authenticate using TouchID.");
        
    }
    
}

@end
