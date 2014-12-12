//
//  ManageLocation.h
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
