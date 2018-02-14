//
//  UniversalLinksContext.h
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 14/02/2018.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OCPrivateLinkError)
{
    OCPrivateLinkErrorFileNotCached,
    OCPrivateLinkErrorFileNotExists,
    OCPrivateLinkErrorNotAuthorized
};

@protocol UniversalLinksStrategy <NSObject>

@required
-(void)handleLink: (void(^)(NSArray *items))success failure:(void(^)(OCPrivateLinkError)) failure;

@end

@interface UniversalLinksContext : NSObject {
    __unsafe_unretained id<UniversalLinksStrategy> strategy;
}
@property (assign) id<UniversalLinksStrategy> strategy;

-(void)handleLink: (void(^)(NSArray *items))success failure:(void(^)(OCPrivateLinkError)) failure;

@end
