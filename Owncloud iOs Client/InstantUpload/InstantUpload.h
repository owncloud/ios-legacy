//
//  InstantUpload.h
//  Owncloud iOs Client
//

#import <Foundation/Foundation.h>

@protocol InstantUploadDelegate <NSObject>

- (void) instantUploadPermissionLostOrDenied;
- (void) backgroundInstantUploadPermissionLostOrDenied;

@end

@interface InstantUpload : NSObject

@property (weak) id<InstantUploadDelegate> delegate;

+ (instancetype) instantUploadManager;

- (BOOL) enabled;
- (void) setEnabled:(BOOL)enabled;

- (BOOL) backgroundInstantUploadEnabled;
- (void) setBackgroundInstantUploadEnabled:(BOOL)enabled;

- (void) activate;

@end
