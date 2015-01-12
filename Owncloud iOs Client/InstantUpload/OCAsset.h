//
//  OCAsset.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface OCAsset : NSObject

@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic, weak) NSDate * date;

- (id)initWithAsset:(ALAsset*)asset;

@end
