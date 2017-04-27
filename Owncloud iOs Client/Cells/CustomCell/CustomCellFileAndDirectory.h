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

@property(nonatomic, weak) IBOutlet UIImageView *fileImageView;
@property(nonatomic, weak) IBOutlet UIImageView *imageDownloaded;
@property(nonatomic, weak) IBOutlet UIImageView *imageAvailableOffline;
@property(nonatomic, weak) IBOutlet UILabel *labelTitle;
@property(nonatomic, weak) IBOutlet UILabel *labelInfoFile;
@property(nonatomic, weak) IBOutlet UIImageView *sharedByLinkImage;
@property(nonatomic, weak) IBOutlet UIImageView *sharedWithUsImage;

@property(nonatomic, strong) NSURLSessionTask *thumbnailSessionTask;

//Last position of the scroll of the swipe
@property (nonatomic, assign) CGFloat lastContentOffset;

//Index path of the cell swipe gesture ocured
@property (nonatomic, strong) NSIndexPath *indexPath;

@end
