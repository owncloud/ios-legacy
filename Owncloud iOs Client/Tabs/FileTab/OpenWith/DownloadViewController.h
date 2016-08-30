//
//  DownloadViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 22/08/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>

@protocol DownloadViewControllerDelegate

@optional
- (void)cancelDownload;
@end

@interface DownloadViewController : UIViewController{
    
    UIProgressView *_progressView;
    UIButton *_cancelButton;
    UILabel *_progressLabel;
    __weak id<DownloadViewControllerDelegate> delegate;
    
    IBOutlet NSLayoutConstraint *_heightProgressBar;
    
}

@property(nonatomic, strong) IBOutlet UIProgressView *progressView;
@property(nonatomic, strong) IBOutlet UIButton *cancelButton;
@property(nonatomic, strong) IBOutlet UILabel *progressLabel;
@property(nonatomic,weak) __weak id<DownloadViewControllerDelegate> delegate; 


-(IBAction)cancelButtonPressed:(id)sender;
-(void)configureView;
-(void)potraitView;
-(void)landscapeView;

@end
