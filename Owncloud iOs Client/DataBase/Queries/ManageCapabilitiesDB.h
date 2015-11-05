//
//  ManageCapabilitiesDB.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/11/15.
//
//

#import <Foundation/Foundation.h>

@class CapabilitiesDto;
@class OCCapabilities;

@interface ManageCapabilitiesDB : NSObject

+(CapabilitiesDto *) insertCapabilities:(OCCapabilities *)capabilities ofUserId:(NSInteger)userId;

+(CapabilitiesDto *) getCapabilitiesOfUserId:(NSInteger) userId;

+(CapabilitiesDto *) updateCapabilitiesWith:(OCCapabilities *)capabilities ofUserId:(NSInteger)userId;



@end
