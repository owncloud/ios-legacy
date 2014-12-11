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
        if(IS_IOS8){
            [self.locationManager requestAlwaysAuthorization];
        }
            
        //self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //self.locationManager.distanceFilter = 0; // meters
    }
    
   
    [self.locationManager startMonitoringSignificantLocationChanges];
}

-(void)stopSignificantChangeUpdates{
    
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{

     /*  CLLocation* location = [locations lastObject];
    
    NSDate* eventDate = location.timestamp;
    
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    if (abs(howRecent) < 15.0) {
        
        // If the event is recent, do something with it.
        
        DLog(@"latitude %+.6f, longitude %+.6f\n",
              
              location.coordinate.latitude,
              
              location.coordinate.longitude);
        
    }*/
    
   /* for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    }*/

    
    //do
    [self presentNotification];
    
}



-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
        DLog(@"Unable to start location manager. Error:%@", [error description]);
}


-(void)presentNotification{
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"Location updated!!";
    localNotification.alertAction = @"Background Location change";
    
    
    //On sound
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

@end
