//
//  OCLoadingSpinner.h
//  Owncloud iOs Client
//
//  Created by María Rodríguez on 25/05/16.
//
//

#import <UIKit/UIKit.h>

@interface OCLoadingSpinner : NSObject

+ (id)sharedOCLoadingSpinner;

- (void)initLoadingForViewController:(UIViewController *)vc;
- (void)endLoading;


@end
