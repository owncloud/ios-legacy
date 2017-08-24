//
//  RMCustomViewController.h
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 22/08/2017.
//
//

#import <RMActionController/RMActionController.h>

@interface RMCustomViewController : RMActionController<UIView *>

@property(nonatomic, strong) NSString *fileName;
@property(nonatomic, strong) NSString *filePath;
@property(nonatomic, strong) UIImage *fileIcon;
@property(nonatomic, strong) UIImageView *fileIconImageView;
@property(nonatomic, strong) UILabel *fileNameLabel;
@property(nonatomic, strong) UILabel *filePathLabel;


@end
