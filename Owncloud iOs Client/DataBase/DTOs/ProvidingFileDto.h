//
//  ProvidingFileDto.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 2/1/15.
//
//

#import <Foundation/Foundation.h>

@interface ProvidingFileDto : NSObject

@property (nonatomic) NSInteger idProvidingFile;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic) NSInteger userId;

@end
