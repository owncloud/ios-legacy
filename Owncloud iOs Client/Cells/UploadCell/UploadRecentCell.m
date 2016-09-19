//
//  UploadRecentCell.m
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

#import "UploadRecentCell.h"

@implementation UploadRecentCell

@synthesize labelTitle=_labelTitle;
@synthesize labelLengthAndDate=_labelLengthAndDate;
@synthesize labelUserName=_labelUserName;
@synthesize labelPath=_labelPath;
@synthesize fileImageView=_fileImageView;



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
