//
//  CustomCellFileAndDirectory.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 29/07/12.

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface CustomCellFileAndDirectory : SWTableViewCell

@property(weak, nonatomic) IBOutlet UIImageView *fileImageView;
@property(weak, nonatomic) IBOutlet UIImageView *imageFileStatus;
@property(weak, nonatomic) IBOutlet UILabel *labelTitle;
@property(weak, nonatomic) IBOutlet UILabel *labelInfoFile;
@property(weak, nonatomic) IBOutlet UIButton *sharedInfoButton;
@property (weak, nonatomic) IBOutlet UIButton *sharedWithMeButton;
@property (weak, nonatomic) IBOutlet UILabel *sharedInfoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *sharedInfoImageView;

@property(nonatomic, strong) NSURLSessionTask *thumbnailSessionTask;

//Last position of the scroll of the swipe
@property (nonatomic, assign) CGFloat lastContentOffset;

//Index path of the cell swipe gesture ocured
@property (nonatomic, strong) NSIndexPath *indexPath;

@end
