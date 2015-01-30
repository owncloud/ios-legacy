//
//  ManageLocation.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 09/12/14.
//
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "ManageLocation.h"
#import "SettingsViewController.h"
#import "ManageAppSettingsDB.h"
#import "ManageAsset.h"

@implementation ManageLocation

+ (ManageLocation *)sharedSingleton {
    static ManageLocation *sharedSingleton;
    @synchronized(self)
    {
        if (!sharedSingleton){
            sharedSingleton = [[ManageLocation alloc] init];
        }
        return sharedSingleton;
    }
}

-(void)startSignificantChangeUpdates {
    
    if (nil == self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
            [self.locationManager requestAlwaysAuthorization];
        }
        
    }
   
    [self.locationManager startMonitoringSignificantLocationChanges];
}

-(void)stopSignificantChangeUpdates {
    
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

      CLLocation* location = [locations lastObject];
    
    DLog(@"latitude__ %+.6f, longitude__ %+.6f\n",
         
         location.coordinate.latitude,
         
         location.coordinate.longitude);

    [self.delegate changedLocation];

}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    
        [self.delegate statusAuthorizationLocationChanged];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
        DLog(@"Unable to start location manager. Error:%@", [error description]);
     [self.delegate statusAuthorizationLocationChanged];
    
}

@end
