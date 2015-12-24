//
//  ManageThumbnails.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 23/12/15.
//
//

#import <Foundation/Foundation.h>

@interface ManageThumbnails : NSObject

+ (id) sharedManager;

- (BOOL) isStoredThumbnailWithHash:(NSUInteger) hash;
- (BOOL) storeThumbnail:(NSData *)thumbnail withHash:(NSUInteger) hash;
- (BOOL) removeStoredThumbnailWithHash:(NSUInteger) hash;
- (NSString *) getThumbnailPathForFileHash:(NSUInteger) hash;
- (BOOL) renameStoredThumbnailWithOldHash:(NSUInteger) oldHash withNewHash:(NSUInteger) newHash;

@end
