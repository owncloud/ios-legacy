//
//  RMOCViewController.m
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 25/08/2017.
//
//

#import "RMOCViewController.h"

@interface RMOCViewController ()

@end

@implementation RMOCViewController


- (instancetype)initWithStyle:(RMActionControllerStyle)aStyle title:(NSString *)aTitle message:(NSString *)aMessage selectAction:(RMAction *)selectAction andCancelAction:(RMAction *)cancelAction {
    self = [super initWithStyle:aStyle title:@"" message:@"" selectAction:selectAction andCancelAction:cancelAction];
    if(self){
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        NSDictionary *bindings = @{@"contentView": self.contentView};

    }
    return self;
}




@end
