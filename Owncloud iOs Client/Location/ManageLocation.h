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

@protocol ManageLocationDelegate

@optional
- (void)statusAuthorizationLocationChanged;
@end

@interface ManageLocation : NSObject <CLLocationManagerDelegate>

@property CLLocationManager *locationManager;
@property BOOL firstChangeAuthorizationDone;
@property(nonatomic,weak) __weak id<ManageLocationDelegate> delegate;

+ (ManageLocation *) sharedSingleton;
-(void)startSignificantChangeUpdates;
-(void)stopSignificantChangeUpdates;

@end
