//
//  RMCustomViewController.m
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 22/08/2017.
//
//

#import "RMCustomViewController.h"

@implementation RMCustomViewController

#pragma mark - Init and Dealloc
- (instancetype)initWithStyle:(RMActionControllerStyle)aStyle title:(NSString *)aTitle message:(NSString *)aMessage selectAction:(RMAction *)selectAction andCancelAction:(RMAction *)cancelAction {
    self = [super initWithStyle:aStyle title:aTitle message:aMessage selectAction:selectAction andCancelAction:cancelAction];
    if(self) {
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView setFrame:CGRectMake(self.contentView.bounds.origin.x, self.contentView.bounds.origin.y, self.contentView.bounds.size.width, 75)];
        
        UIImageView *fileImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        fileImage.translatesAutoresizingMaskIntoConstraints = NO;
        [fileImage setImage: [UIImage imageNamed:@"file_icon"]];
        [fileImage setContentMode: UIViewContentModeScaleToFill];
        [self.contentView addSubview:fileImage];
        
        UILabel *fileName = [[UILabel alloc] initWithFrame:CGRectZero];
        fileName.translatesAutoresizingMaskIntoConstraints = NO;
        fileName.text = @"FileName";
        fileName.font = [UIFont fontWithName:@"SourceSansPro-bold" size:15];
        [self.contentView addSubview:fileName];
        
        UILabel *filePath = [[UILabel alloc] initWithFrame:CGRectZero];
        filePath.translatesAutoresizingMaskIntoConstraints = NO;
        filePath.text = @"FilePath";
        filePath.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:15];
        [self.contentView addSubview:filePath];

        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem: fileImage
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0
                                                            constant:25]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem: fileImage
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0
                                                            constant:25]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:fileImage
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                            attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                            constant:15]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:fileImage
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                            attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                            constant:0]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:fileName
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:fileImage
                                                            attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                            constant:15]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:fileName
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                            attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                            constant:-10]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:filePath
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:fileImage
                                                            attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                            constant:15]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:filePath
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                            attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                            constant:10]];
        
        
        
        NSDictionary *bindings = @{@"contentView": self.contentView};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(>=300)]" options:0 metrics:nil views:bindings]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView(75)]" options:0 metrics:nil views:bindings]];
    }
    return self;
}

@end
