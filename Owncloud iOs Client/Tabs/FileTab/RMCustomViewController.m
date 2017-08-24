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
    
    
    
    self = [super initWithStyle:aStyle title:@"" message:@"" selectAction:selectAction andCancelAction:cancelAction];
    if(self) {
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView setFrame:CGRectMake(self.contentView.bounds.origin.x, self.contentView.bounds.origin.y, self.contentView.bounds.size.width, 75)];
        
        self.fileIconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _fileIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_fileIconImageView setImage: self.fileIcon];
        [_fileIconImageView setContentMode: UIViewContentModeScaleToFill];
        [self.contentView addSubview:_fileIconImageView];
        
        self.fileNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _fileNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _fileNameLabel.text = self.fileName;
        _fileNameLabel.textColor = [[UIColor alloc] initWithRed:90.0f/255.0f green:105.0f/255.0f blue:120.0f/255.0f alpha:1.0];
        _fileNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
        [self.contentView addSubview:_fileNameLabel];
        
        self.filePathLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _filePathLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _filePathLabel.text = self.filePath;
        _filePathLabel.textColor = [[UIColor alloc] initWithRed:150.0f/255.0f green:159.0f/255.0f blue:170.0f/255.0f alpha:1.0];
        _filePathLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:15];
        [self.contentView addSubview:_filePathLabel];

        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileIconImageView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0
                                                            constant:50]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileIconImageView
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0
                                                            constant:50]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileIconImageView
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                            attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                            constant:15]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileIconImageView
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                            attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                            constant:0]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileNameLabel
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:_fileIconImageView
                                                            attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                            constant:15]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_fileNameLabel
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                            attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                            constant:-10]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_filePathLabel
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                            toItem:_fileIconImageView
                                                            attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                            constant:15]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_filePathLabel
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
