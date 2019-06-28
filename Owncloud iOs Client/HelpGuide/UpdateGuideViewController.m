//
//  UpdateGuideViewController.m
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

#import "UpdateGuideViewController.h"
#import "UIColor+Constants.h"
#import "MyCustomAnimation.h"
#import "UIImage+Device.h"

@implementation UpdateGuideViewController

- (void)configureTextLabelsAndButtons{

	//Titles labels
	self.welcomeLabel = [UILabel new];
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	self.welcomeLabel.text = [NSLocalizedString(@"title_update_slide_0", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName];
	self.welcomeLabel.textColor = [UIColor colorOfLoginText];
	[self.welcomeLabel setFont:[UIFont boldSystemFontOfSize:20]];
	[self.welcomeLabel sizeToFit];
	[self.contentView addSubview:self.welcomeLabel];

	self.firstLabel = [UILabel new];
	self.firstLabel.text = NSLocalizedString(@"title_update_slide_1", nil);
	self.firstLabel.textColor = [UIColor colorOfLoginText];
	[self.firstLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.firstLabel sizeToFit];
	[self.contentView addSubview:self.firstLabel];

	self.secondLabel = [UILabel new];
	self.secondLabel.text = NSLocalizedString(@"title_update_slide_2", nil);
	self.secondLabel.textColor = [UIColor colorOfLoginText];
	[self.secondLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.secondLabel sizeToFit];
	[self.contentView addSubview:self.secondLabel];

	self.thirdLabel = [UILabel new];
	self.thirdLabel.text = NSLocalizedString(@"title_update_slide_3", nil);
	self.thirdLabel.textColor = [UIColor colorOfLoginText];
	[self.thirdLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.thirdLabel sizeToFit];
	[self.contentView addSubview:self.thirdLabel];

	self.fourthLabel = [UILabel new];
	self.fourthLabel.text = NSLocalizedString(@"title_update_slide_4", nil);
	self.fourthLabel.textColor = [UIColor colorOfLoginText];
	[self.fourthLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.fourthLabel sizeToFit];
	[self.contentView addSubview:self.fourthLabel];

	self.fifthLabel = [UILabel new];
	self.fifthLabel.text = NSLocalizedString(@"title_update_slide_5", nil);
	self.fifthLabel.textColor = [UIColor colorOfLoginText];
	[self.fifthLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.fifthLabel sizeToFit];
	[self.contentView addSubview:self.fifthLabel];

	//Message labels
	self.messageWelcomeLabel = [UILabel new];
	self.messageWelcomeLabel.text = NSLocalizedString(@"message_update_slide_0", nil);
	self.messageWelcomeLabel.textColor = [UIColor colorOfLoginText];
	[self.messageWelcomeLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.messageWelcomeLabel sizeToFit];
	[self.contentView addSubview:self.messageWelcomeLabel];

	self.messageFirstLabel = [UILabel new];
	self.messageFirstLabel.text = NSLocalizedString(@"message_update_slide_1", nil);
	self.messageFirstLabel.textColor = [UIColor colorOfLoginText];
	[self.messageFirstLabel sizeToFit];
	[self.contentView addSubview:self.messageFirstLabel];

	self.messageSecondLabel = [UILabel new];
	self.messageSecondLabel.text = NSLocalizedString(@"message_update_slide_2", nil);
	self.messageSecondLabel.textColor = [UIColor colorOfLoginText];
	self.messageSecondLabel.numberOfLines = 2;
	[self.messageSecondLabel sizeToFit];
	[self.contentView addSubview:self.messageSecondLabel];

	self.messageThirdLabel = [UILabel new];
	self.messageThirdLabel.text = NSLocalizedString(@"message_update_slide_3", nil);
	self.messageThirdLabel.textColor = [UIColor colorOfLoginText];
	[self.messageThirdLabel sizeToFit];
	[self.contentView addSubview:self.messageThirdLabel];

	self.messageFourthLabel = [UILabel new];
	self.messageFourthLabel.text = NSLocalizedString(@"message_update_slide_4", nil);
	self.messageFourthLabel.textColor = [UIColor colorOfLoginText];
	[self.messageFourthLabel sizeToFit];
	[self.contentView addSubview:self.messageFourthLabel];

	//Button skip update guide
	self.skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[self.skipButton setTitle:NSLocalizedString(@"skip_button_update_guide", nil) forState:UIControlStateNormal];
	[self.skipButton setBackgroundColor:[UIColor colorOfLoginButtonBackground]];
	[self.skipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.skipButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
	[self.skipButton addTarget:self action:@selector(stayPressed:) forControlEvents:UIControlEventTouchDown];
	self.skipButton.contentEdgeInsets = UIEdgeInsetsMake(7, 20, 7, 20);
	self.skipButton.layer.cornerRadius = 6.0;

	[self.contentView addSubview:self.skipButton];

	//Button sign in
	self.signInButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[self.signInButton setTitle:NSLocalizedString(@"sign_in_button_update_guide", nil) forState:UIControlStateNormal];
	[self.signInButton setBackgroundColor:[UIColor colorOfLoginButtonBackground]];
	[self.signInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.signInButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.signInButton addTarget:self action:@selector(stayPressed:) forControlEvents:UIControlEventTouchDown];
	self.signInButton.contentEdgeInsets = UIEdgeInsetsMake(7, 20, 7, 20);
	self.signInButton.layer.cornerRadius = 6.0;
	[self.contentView addSubview:self.signInButton];

	//Button skip update guide
	self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.closeButton setImage:[UIImage imageNamed:@"dismiss"] forState:UIControlStateNormal];
	self.closeButton.tintColor = UIColor.lightGrayColor;
	[self.closeButton addTarget:self action:@selector(dismissView:) forControlEvents:UIControlEventTouchDown];

	[self.contentView addSubview:self.closeButton];
}

- (void)configureView0 {

	self.owncloudLogo = [[UIImageView alloc] initWithImage:[UIImage deviceImageNamed:@"teaser_photos"]];
	[self.contentView addSubview:self.owncloudLogo];
}

- (void)configureView1 {
	self.iphoneInstantUpload = [[UIImageView alloc] initWithImage:[UIImage deviceImageNamed:@"teaser_pdf"]];
	[self.contentView addSubview:self.iphoneInstantUpload];
}

- (void)configureView2 {

	self.fileAction = [[UIImageView alloc] initWithImage:[UIImage deviceImageNamed:@"teaser_action"]];
	[self.contentView addSubview:self.fileAction];
	self.iphoneFiles = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iphoneFiles"]];
	[self.contentView addSubview:self.iphoneFiles];
}

- (void)configureView3 {
	self.iphoneShare = [[UIImageView alloc] initWithImage:[UIImage deviceImageNamed:@"teaser_quick"]];
	[self.contentView addSubview:self.iphoneShare];
}

- (void)configureView4 {
	self.iphoneAccounts = [[UIImageView alloc] initWithImage:[UIImage deviceImageNamed:@"teaser_accounts"]];
	[self.contentView addSubview:self.iphoneAccounts];
}

- (void)configureView5 {

	self.appIcon = [[UIImageView alloc] initWithImage:[UIImage deviceImageNamed:@"teaser_app_icon"]];
	self.appIcon.layer.masksToBounds = YES;
	self.appIcon.layer.cornerRadius = 30;
	[self.contentView addSubview:self.appIcon];

	self.owncloudLogoFiles = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"owncloudLogoFiles"]];
	[self.contentView addSubview:self.owncloudLogoFiles];
}

- (void) configureView1Animations {
	[self keepView:self.iphoneInstantUpload onPages:@[@(1)]];
	[self keepView:self.fileAction onPages:@[ @(1), @(2)]];
	[self keepView:self.closeButton onPages:@[@(0), @(1), @(2), @(3), @(4), @(5)]];

	NSLayoutConstraint *closeButtonCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.closeButton
																					attribute:NSLayoutAttributeTop
																					relatedBy:NSLayoutRelationEqual
																					   toItem:self.contentView
																					attribute:NSLayoutAttributeTop
																				   multiplier:1.0 constant:40.f];
	[self.contentView addConstraint:closeButtonCenterYConstraint];

	NSLayoutConstraint *iphoneInstantUploadCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.iphoneInstantUpload
																							attribute:NSLayoutAttributeCenterY
																							relatedBy:NSLayoutRelationEqual
																							   toItem:self.contentView
																							attribute:NSLayoutAttributeCenterY
																						   multiplier:0.8 constant:0.f];
	[self.contentView addConstraint:iphoneInstantUploadCenterYConstraint];



	NSLayoutConstraint *fileActionCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.fileAction
																				   attribute:NSLayoutAttributeCenterY
																				   relatedBy:NSLayoutRelationEqual
																					  toItem:self.contentView
																				   attribute:NSLayoutAttributeCenterY
																				  multiplier:0.2f constant:0.f];

	[self.contentView addConstraint:fileActionCenterYConstraint];

	// Move the owncloudLogo from a bit higher than center on page 1 to a bit lower on page 2, by an amount relative to the height of the view.
	IFTTTConstraintMultiplierAnimation *ownCloudLogoCenterYAnimation = [IFTTTConstraintMultiplierAnimation animationWithSuperview:self.contentView
																										constraint:fileActionCenterYConstraint			attribute:IFTTTLayoutAttributeHeight			referenceView:self.contentView];

	[ownCloudLogoCenterYAnimation addKeyframeForTime:1 multiplier:-0.1f];
	[ownCloudLogoCenterYAnimation addKeyframeForTime:2 multiplier:0.42f];
	[ownCloudLogoCenterYAnimation addKeyframeForTime:3 multiplier:0.1f];
	[self.animator addAnimation:ownCloudLogoCenterYAnimation];


	// Scale down the company logo by 75% between pages 0 and 1
	IFTTTScaleAnimation *ownCloudLogoScaleAnimation = [IFTTTScaleAnimation animationWithView:self.fileAction];
	//[ownCloudLogoScaleAnimation addKeyframeForTime:0 scale:1.f];
	[ownCloudLogoScaleAnimation addKeyframeForTime:1 scale:0.80f];
	[ownCloudLogoScaleAnimation addKeyframeForTime:2 scale:1.f];
	[self.animator addAnimation:ownCloudLogoScaleAnimation];

	// fade the owncloud in on page 0 and out on page 2
	IFTTTAlphaAnimation *iphoneFilesAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.fileAction];
	[iphoneFilesAlphaAnimation addKeyframeForTime:1 alpha:0.f];
	[iphoneFilesAlphaAnimation addKeyframeForTime:2 alpha:1.f];
	[iphoneFilesAlphaAnimation addKeyframeForTime:3 alpha:0.f];
	[self.animator addAnimation:iphoneFilesAlphaAnimation];
}

- (void) configureView2Animations {
	[self keepView:self.iphoneFiles onPages:@[ @(2)]];

	NSLayoutConstraint *iphoneFilesCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.iphoneFiles
																					attribute:NSLayoutAttributeCenterY
																					relatedBy:NSLayoutRelationEqual
																					   toItem:self.contentView
																					attribute:NSLayoutAttributeCenterY
																				   multiplier:0.55f constant:0.f];
	[self.contentView addConstraint:iphoneFilesCenterYConstraint];

	// fade the owncloud in on page 0 and out on page 2
	IFTTTAlphaAnimation *iphoneFilesAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.iphoneFiles];
	[iphoneFilesAlphaAnimation addKeyframeForTime:1 alpha:0.f];
	[iphoneFilesAlphaAnimation addKeyframeForTime:2 alpha:1.f];
	[iphoneFilesAlphaAnimation addKeyframeForTime:3 alpha:0.f];
	[self.animator addAnimation:iphoneFilesAlphaAnimation];
}

- (void) configureView3Animations {
	[self keepView:self.iphoneShare onPages:@[@(3)]];

	NSLayoutConstraint *iphoneShareCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.iphoneShare
																					attribute:NSLayoutAttributeCenterY
																					relatedBy:NSLayoutRelationEqual
																					   toItem:self.contentView
																					attribute:NSLayoutAttributeCenterY
																				   multiplier:0.8f constant:0.f];
	[self.contentView addConstraint:iphoneShareCenterYConstraint];

	// fade the owncloud in on page 0 and out on page 2
	IFTTTAlphaAnimation *iphoneShareAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.iphoneShare];
	[iphoneShareAlphaAnimation addKeyframeForTime:2 alpha:0.f];
	[iphoneShareAlphaAnimation addKeyframeForTime:3 alpha:1.f];
	[iphoneShareAlphaAnimation addKeyframeForTime:4 alpha:0.f];
	[self.animator addAnimation:iphoneShareAlphaAnimation];

	// Scale down the company logo by 75% between pages 0 and 1
	IFTTTScaleAnimation *ownCloudLogoScaleAnimation = [IFTTTScaleAnimation animationWithView:self.iphoneShare];
	[ownCloudLogoScaleAnimation addKeyframeForTime:2 scale:3.5f];
	[ownCloudLogoScaleAnimation addKeyframeForTime:3 scale:1.f];
	[self.animator addAnimation:ownCloudLogoScaleAnimation];
}

- (void) configureView4Animations {
	[self keepView:self.iphoneAccounts onPages:@[@(4)]];

	NSLayoutConstraint *iphoneAccountsCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.iphoneAccounts
																					   attribute:NSLayoutAttributeCenterY
																					   relatedBy:NSLayoutRelationEqual
																						  toItem:self.contentView
																					   attribute:NSLayoutAttributeCenterY
																					  multiplier:0.8f constant:0.f];
	[self.contentView addConstraint:iphoneAccountsCenterYConstraint];

	// fade the owncloud in on page 0 and out on page 2
	IFTTTAlphaAnimation *iphoneAccountAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.iphoneAccounts];
	[iphoneAccountAlphaAnimation addKeyframeForTime:3 alpha:0.f];
	[iphoneAccountAlphaAnimation addKeyframeForTime:4 alpha:1.f];
	[iphoneAccountAlphaAnimation addKeyframeForTime:5 alpha:0.f];
	[self.animator addAnimation:iphoneAccountAlphaAnimation];
}

- (void) configureView5Animations {
	[self keepView:self.appIcon onPages:@[@(5)]];

	NSLayoutConstraint *ownCloudLogoCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.appIcon
																					 attribute:NSLayoutAttributeCenterY
																					 relatedBy:NSLayoutRelationEqual
																						toItem:self.contentView
																					 attribute:NSLayoutAttributeCenterY
																					multiplier:0.9f constant:0.f];
	[self.contentView addConstraint:ownCloudLogoCenterYConstraint];

	IFTTTAlphaAnimation *appIconAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.appIcon];
	[appIconAlphaAnimation addKeyframeForTime:4 alpha:0.f];
	[appIconAlphaAnimation addKeyframeForTime:5 alpha:1.f];
	[self.animator addAnimation:appIconAlphaAnimation];


	// Scale down the company logo by 75% between pages 0 and 1
	IFTTTScaleAnimation *ownCloudLogoScaleAnimation = [IFTTTScaleAnimation animationWithView:self.appIcon];
	[ownCloudLogoScaleAnimation addKeyframeForTime:4 scale:0.5f];
	[ownCloudLogoScaleAnimation addKeyframeForTime:5 scale:1.f];
	[self.animator addAnimation:ownCloudLogoScaleAnimation];



	[self keepView:self.owncloudLogoFiles onPages:@[@(5)]];

	NSLayoutConstraint *owncloudLogoFilesCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.owncloudLogoFiles
																						  attribute:NSLayoutAttributeCenterY
																						  relatedBy:NSLayoutRelationEqual
																							 toItem:self.contentView
																						  attribute:NSLayoutAttributeCenterY
																						 multiplier:0.6f constant:0.f];
	[self.contentView addConstraint:owncloudLogoFilesCenterYConstraint];

	// fade the owncloud in on page 0 and out on page 2
	IFTTTAlphaAnimation *owncloudLogoFilesAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.owncloudLogoFiles];
	[owncloudLogoFilesAlphaAnimation addKeyframeForTime:4 alpha:0.f];
	[owncloudLogoFilesAlphaAnimation addKeyframeForTime:5 alpha:1.f];
	[self.animator addAnimation:owncloudLogoFilesAlphaAnimation];

	// Scale down the company logo by 75% between pages 0 and 1
	IFTTTScaleAnimation *ownCloudLogoScaleAnimation2 = [IFTTTScaleAnimation animationWithView:self.owncloudLogoFiles];
	[ownCloudLogoScaleAnimation2 addKeyframeForTime:4 scale:0.6f];
	[ownCloudLogoScaleAnimation2 addKeyframeForTime:5 scale:1.3f];
	[self.animator addAnimation:ownCloudLogoScaleAnimation2];
}

- (void)configureLabelAnimations
{
	// lay out labels' vertical positions
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.welcomeLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:0.4f constant:0.f]];

	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.firstLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.5f constant:0.f]];
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.secondLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.5f constant:0.f]];
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.thirdLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.5f constant:0.f]];
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.fourthLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.5f constant:0.f]];
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.fifthLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.2f constant:0.f]];


	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.signInButton
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.4f constant:0.f]];

	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.skipButton
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.6f constant:0.f]];


	//subtitles
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageWelcomeLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.4f constant:0.f]];

	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageFirstLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.6f constant:0.f]];

	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageSecondLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.6f constant:0.f]];

	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageThirdLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.6f constant:0.f]];

	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageFourthLabel
																 attribute:NSLayoutAttributeCenterY
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.6f constant:0.f]];

	// lay out the labels' horizontal positions (centered on each page)
	[self keepView:self.welcomeLabel onPage:0];
	[self keepView:self.firstLabel onPage:1];
	[self keepView:self.secondLabel onPage:2];
	[self keepView:self.thirdLabel onPage:3];
	[self keepView:self.fourthLabel onPage:4];
	[self keepView:self.fifthLabel onPage:5];

	[self keepView:self.signInButton onPage:5];
	[self keepView:self.skipButton onPage:0];

	[self keepView:self.messageWelcomeLabel onPage:0];
	[self keepView:self.messageFirstLabel onPage:1];
	[self keepView:self.messageSecondLabel onPage:2];
	[self keepView:self.messageThirdLabel onPage:3];
	[self keepView:self.messageFourthLabel onPage:4];

	// apply a 3D zoom animation to the first label
	IFTTTTransform3DAnimation * labelTransform = [IFTTTTransform3DAnimation animationWithView:self.welcomeLabel];
	IFTTTTransform3D *tt1 = [IFTTTTransform3D transformWithM34:0.03f];
	IFTTTTransform3D *tt2 = [IFTTTTransform3D transformWithM34:0.3f];
	tt2.rotate = (IFTTTTransform3DRotate){ -(CGFloat)(M_PI), 1, 0, 0 };
	tt2.translate = (IFTTTTransform3DTranslate){ 0, 0, 50 };
	tt2.scale = (IFTTTTransform3DScale){ 1.f, 2.f, 1.f };
	[labelTransform addKeyframeForTime:0 transform:tt1];
	[labelTransform addKeyframeForTime:0.5f transform:tt2];
	[self.animator addAnimation:labelTransform];

	// fade out the first label
	IFTTTAlphaAnimation *firstLabelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.welcomeLabel];
	[firstLabelAlphaAnimation addKeyframeForTime:0 alpha:1.f];
	[firstLabelAlphaAnimation addKeyframeForTime:0.35f alpha:0.f];
	[self.animator addAnimation:firstLabelAlphaAnimation];

	// custom animate the fourth label
	MyCustomAnimation *fourthLabelAnimation = [MyCustomAnimation animationWithView:self.fourthLabel];
	[fourthLabelAnimation addKeyframeForTime:1.5f shadowOpacity:0.f];
	[fourthLabelAnimation addKeyframeForTime:2 shadowOpacity:1.f];
	[fourthLabelAnimation addKeyframeForTime:2.5f shadowOpacity:0.f];
	[self.animator addAnimation:fourthLabelAnimation];

	self.thirdLabel.layer.shadowColor = [UIColor darkGrayColor].CGColor;
	self.thirdLabel.layer.shadowRadius = 1.f;
	self.thirdLabel.layer.shadowOffset = CGSizeMake(1.f, 1.f);

	// Fade out the last label by dragging on the last page
	IFTTTAlphaAnimation *lastLabelAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.fifthLabel];
	[lastLabelAlphaAnimation addKeyframeForTime:5 alpha:1.f];
	[lastLabelAlphaAnimation addKeyframeForTime:5.35f alpha:0.f];
	[self.animator addAnimation:lastLabelAlphaAnimation];
}

- (void)configureOwnCloudLogoAnimations
{
	// now, we animate the ownCloudLogo
	// keep the owncloudLogo centered when we're on pages 1 and 2.
	// It will slide from the right between pages 0 and 1, and slide out to the left between pages 2 and 3.
	[self keepView:self.owncloudLogo onPages:@[@(0), @(1)]];

	NSLayoutConstraint *ownCloudLogoCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.owncloudLogo
																					 attribute:NSLayoutAttributeCenterY
																					 relatedBy:NSLayoutRelationEqual
																						toItem:self.contentView
																					 attribute:NSLayoutAttributeCenterY
																					multiplier:0.7f constant:0.f];
	[self.contentView addConstraint:ownCloudLogoCenterYConstraint];

	// Move the owncloudLogo from a bit higher than center on page 1 to a bit lower on page 2, by an amount relative to the height of the view.
	IFTTTConstraintMultiplierAnimation *ownCloudLogoCenterYAnimation = [IFTTTConstraintMultiplierAnimation animationWithSuperview:self.contentView
																													   constraint:ownCloudLogoCenterYConstraint
																														attribute:IFTTTLayoutAttributeHeight
																													referenceView:self.contentView];
	[ownCloudLogoCenterYAnimation addKeyframeForTime:0 multiplier:0.1f withEasingFunction:IFTTTEasingFunctionEaseOutQuad];
	[ownCloudLogoCenterYAnimation addKeyframeForTime:1 multiplier:-0.1f];
	[self.animator addAnimation:ownCloudLogoCenterYAnimation];

	// Rotate the owncloudLogo a full circle from page 1 to 2
	IFTTTRotationAnimation *ownCloudLogoRotationAnimation = [IFTTTRotationAnimation animationWithView:self.owncloudLogo];
	[ownCloudLogoRotationAnimation addKeyframeForTime:0 rotation:0.f];
	[ownCloudLogoRotationAnimation addKeyframeForTime:1 rotation:360.f];

	[self.animator addAnimation:ownCloudLogoRotationAnimation];

	// Scale down the company logo by 75% between pages 0 and 1
	IFTTTScaleAnimation *ownCloudLogoScaleAnimation = [IFTTTScaleAnimation animationWithView:self.owncloudLogo];
	[ownCloudLogoScaleAnimation addKeyframeForTime:0 scale:1.f];
	[ownCloudLogoScaleAnimation addKeyframeForTime:1 scale:0.80f];
	[self.animator addAnimation:ownCloudLogoScaleAnimation];

	// fade the owncloud in on page 0 and out on page 2
	IFTTTAlphaAnimation *owncloudLogoAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.owncloudLogo];
	[owncloudLogoAlphaAnimation addKeyframeForTime:0 alpha:1.f];
	[owncloudLogoAlphaAnimation addKeyframeForTime:1 alpha:0.f];
	[self.animator addAnimation:owncloudLogoAlphaAnimation];
}

- (void)stayPressed:(UIButton *)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.apple.com/app/id1359583808"]];
	[self dismissView:sender];
}

- (void)dismissView:(UIButton *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didShowUpdateGuide"];
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];

	[app showPassCodeIfNeeded];
}

@end
