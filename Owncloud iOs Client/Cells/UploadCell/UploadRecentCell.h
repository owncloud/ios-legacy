//
//  UploadRecentCell.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 13/09/12.

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>

@interface UploadRecentCell : UITableViewCell{
    
    __weak UILabel *_labelTitle;  
    __weak UILabel *_labelLengthAndDate;
    __weak UILabel *_labelUserName;
    __weak UILabel *_labelPath;
    __weak UIImageView *_fileImageView;
}


@property(nonatomic, weak) IBOutlet UILabel *labelTitle;
@property(nonatomic, weak) IBOutlet UILabel *labelLengthAndDate;
@property(nonatomic, weak) IBOutlet UILabel *labelUserName;
@property(nonatomic, weak) IBOutlet UILabel *labelPath;
@property(nonatomic, weak) IBOutlet UIImageView *fileImageView;

@end
