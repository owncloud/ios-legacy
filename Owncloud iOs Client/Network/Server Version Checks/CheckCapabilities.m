//
//  CheckCapabilities.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 3/11/15.
//
//

#import "CheckCapabilities.h"
#import "AppDelegate.h"
#import "ManageUsersDB.h"
#import "OCCommunication.h"
#import "OCCapabilities.h"
#import "CapabilitiesDto.h"
#import "ManageCapabilitiesDB.h"
#import "FileNameUtils.h"
#import "Customization.h"

@implementation CheckCapabilities

+ (id)sharedCheckCapabilities{
    
    static CheckCapabilities *sharedCheckCapabilities = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCheckCapabilities = [[self alloc] init];
    });
    return sharedCheckCapabilities;
    
}

- (void) updateServerCapabilitiesOfActiveAccount {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser.username == nil) {
        app.activeUser = [ManageUsersDB getActiveUser];
    }
    
    if (app.activeUser) {
        
        [[AppDelegate sharedOCCommunication] getCapabilitiesOfServer:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, OCCapabilities *capabilities, NSString *redirectedServer) {
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                if (isSamlCredentialsError) {
                    //TODO: show the login view 
                     //[self errorLogin];
                }
            }
            
            if (!isSamlCredentialsError) {
                CapabilitiesDto *cap = [ManageCapabilitiesDB getCapabilitiesOfUserId: app.activeUser.idUser];
                
                if (cap == nil) {
                    cap = [ManageCapabilitiesDB insertCapabilities:capabilities ofUserId: app.activeUser.idUser];
                }else{
                    cap = [ManageCapabilitiesDB updateCapabilitiesWith:capabilities ofUserId: app.activeUser.idUser];
                }

            }

        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            
             DLog(@"error when try to get server capabilities: %@", error);
            
        }];
    }
    
}

- (void)errorLogin {
    //[self endLoading];
    
    [self.delegate errorLogin];
}

@end
