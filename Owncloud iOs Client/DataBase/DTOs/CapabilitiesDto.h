//
//  CapabilitiesDto.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/11/15.
//
//

#import "OCCapabilities.h"

@interface CapabilitiesDto : OCCapabilities

//The relation between the user and the capabilities. For use in the App
@property (nonatomic) NSInteger idCapabilities;
@property (nonatomic) NSInteger idUser;

@end
