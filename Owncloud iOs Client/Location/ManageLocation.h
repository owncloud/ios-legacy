//
//  ManageLocation.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 09/12/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface ManageLocation : NSObject <CLLocationManagerDelegate>

@property CLLocationManager *locationManager;


+ (ManageLocation *) sharedSingleton;
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
-(void)startSignificantChangeUpdates;
-(void)stopSignificantChangeUpdates;

@end
