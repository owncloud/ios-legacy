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
@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *fullUrl;
@property (nonatomic, strong) NSString * filename;
@property (nonatomic, strong) NSString * fullUrlString;
@property (nonatomic, strong) NSString * type;
@property ALAssetRepresentation* rep;
//@property int byteArraySize;

- (id)initWithAsset:(ALAsset*)asset;

@end
