//
//  OCAsset.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import "OCAsset.h"

@implementation OCAsset

- (id)initWithAsset:(ALAsset*)asset
{
    self = [super init];
    if (self) {
        self.asset = asset;
       // _selected = NO;
    }
    
    return self;
}

@end
