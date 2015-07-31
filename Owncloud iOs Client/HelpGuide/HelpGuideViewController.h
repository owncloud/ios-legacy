//
//  HelpGuideViewController.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 8/7/15.
//
//

/*
 Copyright (C) 2015, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "IFTTTJazzHands.h"

@interface HelpGuideViewController : IFTTTAnimatedPagingScrollViewController

@property (nonatomic, strong) UIImageView *wordmark;
@property (nonatomic, strong) UIImageView *owncloudLogo;

@property (nonatomic, strong) UIImageView *btnAllHelpPage;
@property (nonatomic, strong) UIImageView *btnHelpPage0;
@property (nonatomic, strong) UIImageView *btnHelpPage1;
@property (nonatomic, strong) UIImageView *btnHelpPage2;
@property (nonatomic, strong) UIImageView *btnHelpPage3;
@property (nonatomic, strong) UIImageView *btnHelpPage4;
@property (nonatomic, strong) UIImageView *btnHelpPage5;

@property (nonatomic, strong) UIImageView *iphoneInstantUpload;
@property (nonatomic, strong) UIImageView *iphoneFiles;
@property (nonatomic, strong) UIImageView *iphoneShare;
@property (nonatomic, strong) UIImageView *iphoneAccounts;
@property (nonatomic, strong) UIImageView *owncloudLogoFiles;

@property (nonatomic, strong) UILabel *welcomeLabel;
@property (nonatomic, strong) UILabel *firstLabel;
@property (nonatomic, strong) UILabel *secondLabel;
@property (nonatomic, strong) UILabel *thirdLabel;
@property (nonatomic, strong) UILabel *fourthLabel;
@property (nonatomic, strong) UILabel *fifthLabel;

@property (nonatomic, strong) UILabel *messageWelcomeLabel;
@property (nonatomic, strong) UILabel *messageFirstLabel;
@property (nonatomic, strong) UILabel *messageSecondLabel;
@property (nonatomic, strong) UILabel *messageThirdLabel;
@property (nonatomic, strong) UILabel *messageFourthLabel;

@property (nonatomic, strong) UIButton *signInButton;
@property (nonatomic, strong) UIButton *skipButton;

@end
