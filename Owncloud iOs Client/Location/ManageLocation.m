//
//  ManageLocation.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 09/12/14.
//
//

#import "ManageLocation.h"

@implementation ManageLocation

+ (ManageLocation *)sharedSingleton
{
    static ManageLocation *sharedSingleton;
    @synchronized(self)
    {
        if (!sharedSingleton)
            sharedSingleton = [[ManageLocation alloc] init];
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
            
        //self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
       // self.locationManager.distanceFilter = 0; // meters
    }
    
   
    [self.locationManager startMonitoringSignificantLocationChanges];
}

-(void)stopSignificantChangeUpdates{
    
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{

      CLLocation* location = [locations lastObject];
    
    DLog(@"latitude__ %+.6f, longitude__ %+.6f\n",
         
         location.coordinate.latitude,
         
         location.coordinate.longitude);

    
    //do something
    
    [self presentNotification];
    
}



-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
        DLog(@"Unable to start location manager. Error:%@", [error description]);
}


-(void)presentNotification{
    DLog(@"notication method\n");
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"Location updated!!";
    localNotification.alertAction = @"Background Location change";
    
    
    //On sound
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

@end
