//
//  OCAsset.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import "OCAsset.h"

@implementation OCAsset

@synthesize date;

- (id)initWithAsset:(ALAsset*)asset
{
    self = [super init];
    if (self) {
        self.asset = asset;
        self.date = [asset valueForProperty:ALAssetPropertyDate];
        self.url = [asset valueForProperty:ALAssetPropertyURLs];
        self.type = [asset valueForProperty:ALAssetPropertyType];
        self.rep = [asset defaultRepresentation];
        self.fullUrl = [self.rep url];
        self.fullUrlString = [ [self.rep url] absoluteString];
        self.filename = [self.rep filename];
        self.length = (NSUInteger)self.rep.size;
        //self.byteArraySize = asset.defaultRepresentation.size;
       // _selected = NO;
    }
    
    return self;
}

@end
