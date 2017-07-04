//
//  ShareLinkViewController.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 25/04/17.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "OCSharedDto.h"
#import "ShareUtils.h"
#import "ShareFileOrFolder.h"

typedef NS_ENUM (NSInteger, LinkOptionsViewMode){
    LinkOptionsViewModeCreate,
    LinkOptionsViewModeEdit,
};

@interface ShareLinkViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>


@property (nonatomic) LinkOptionsViewMode linkOptionsViewMode;

@property (strong, nonatomic) IBOutlet UITableView *shareLinkOptionsTableView;

@property (strong, nonatomic) UIView *datePickerContainerView;
@property (strong, nonatomic) UIDatePicker *datePickerView;
@property (strong, nonatomic) UIView *pickerView;

@property (nonatomic, strong) FileDto *fileShared;
@property (nonatomic, strong) OCSharedDto *sharedDto;

@property (nonatomic, strong) NSString *updatedPassword;
@property (nonatomic) long updatedExpirationDate;
@property (nonatomic, strong) NSString *updatedPublicUpload;
@property (nonatomic, strong) NSString *updatedShowFileListing;
@property (nonatomic, strong) NSString *updatedLinkName;

@property (nonatomic) BOOL oldPasswordEnabledState;
@property (nonatomic, strong) NSString *oldPublicUploadState;
@property (nonatomic, strong) NSString *oldShowFileListing;


@property (nonatomic) BOOL showErrorPasswordForced;
@property (nonatomic) BOOL showErrorExpirationForced;


@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;

@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;


- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto andDefaultLinkName:(NSString *)defaultLinkName andLinkOptionsViewMode:(LinkOptionsViewMode)linkOptionsViewMode;

@end
