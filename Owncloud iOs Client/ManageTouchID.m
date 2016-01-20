//
//  ManageTouchID.m
//  Owncloud iOs Client
//
//  Created by María Rodríguez on 20/01/16.
//
//

/*
 Copyright (C) 2016, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <LocalAuthentication/LocalAuthentication.h>
#import "ManageTouchID.h"

@implementation ManageTouchID

+ (BOOL)isTouchIDAvailable {
    
    NSError *error = nil;
    if([[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]){
        return true;
    }
    else{
        DLog(@"touchID not available: %@", error.description);
        return false;
    }
}


// TODO: used where/when necessary
+ (void)touchIDStart {
    
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;
    
    if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]){
        
    }
    
    else{
        DLog(@"touchID error: %@", error.description);
    }
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Unlock ownCloud" reply:^(BOOL success, NSError * error) {
            
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"There was a problem verifying your identity."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
                return;
            }
            
            if (success) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:@"You are the device owner!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
                
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"You are not the device owner."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }];
        
    } else {
        
        //TODO depending on error do one thing or another
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your device cannot authenticate using TouchID."
                                                        message:error.description
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}

@end
