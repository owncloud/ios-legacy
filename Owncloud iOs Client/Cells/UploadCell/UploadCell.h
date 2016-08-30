//
//  UploadCell.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 12/09/12.

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>

@interface UploadCell : UITableViewCell{
    
    __weak UIProgressView * _progressView;
     UIButton *_cancelButton;  
    __weak UIButton *_pauseButton; 
    __weak UILabel *_labelTitle;  
    __weak UIImageView *_fileImageView;
    __weak UILabel *_labelErrorMessage;
    
}

@property(nonatomic, weak) IBOutlet UIProgressView * progressView;
@property(nonatomic, strong) IBOutlet UIButton *cancelButton;
@property(nonatomic, weak) IBOutlet UIButton *pauseButton;
@property(nonatomic, weak) IBOutlet UILabel *labelTitle;
@property(nonatomic, weak) IBOutlet UIImageView *fileImageView;
@property(nonatomic, weak) IBOutlet UILabel *labelErrorMessage;



@end
