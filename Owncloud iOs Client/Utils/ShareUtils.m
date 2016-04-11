//
//  ShareUtils.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 25/1/16.
//
//

#import "ShareUtils.h"
#import "OCShareUser.h"


@implementation ShareUtils

+ (NSMutableArray *) manageTheDuplicatedUsers: (NSMutableArray*) items{
    
    for (OCShareUser *userOrGroup in items) {
        NSMutableArray *restOfItems = [NSMutableArray arrayWithArray:items];
        [restOfItems removeObjectIdenticalTo:userOrGroup];
        
        if(restOfItems.count == 0)
            userOrGroup.isDisplayNameDuplicated = NO;
        
        else{
            for (OCShareUser *tempItem in restOfItems) {
                if ([userOrGroup.displayName isEqualToString:tempItem.displayName] && ((!userOrGroup.server && !tempItem.server) || ([userOrGroup.server isEqualToString:tempItem.server]))){
                    userOrGroup.isDisplayNameDuplicated = YES;
                    break;
                }
            }
        }
    }
    
    return items;
    
}

@end
