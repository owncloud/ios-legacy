//
//  CustomCellFileAndDirectory.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 29/07/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "CustomCellFileAndDirectory.h"

@implementation CustomCellFileAndDirectory

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

///-----------------------------------
/// @name scrollViewWillBeginDecelerating
///-----------------------------------

/**
 * Method to initialize the position where we make the swipe in order to detect the direction
 *
 * @param UIScrollView -> scrollView
 */
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    _lastContentOffset = scrollView.contentOffset.x;
}

@end
