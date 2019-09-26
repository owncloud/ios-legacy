//
//  UpdateGuideViewController.h
//  Owncloud iOs Client
//
//  Created by Matthias Hühne on 26.06.19.
//

/*
 Copyright (C) 2019, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "HelpGuideViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface UpdateGuideViewController : HelpGuideViewController

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *appIcon;
@property (nonatomic, strong) UIImageView *fileAction;
@property (assign) id delegate;

@end

NS_ASSUME_NONNULL_END
