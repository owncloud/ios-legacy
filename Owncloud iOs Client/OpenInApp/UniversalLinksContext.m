//
//  UniversalLinksContext.m
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 14/02/2018.
//

#import "UniversalLinksContext.h"

@implementation UniversalLinksContext

@synthesize strategy;

-(void)handleLink:(void (^)(NSArray *))success failure:(void (^)(OCPrivateLinkError))failure {
    [strategy handleLink:success failure:failure];
}

@end
