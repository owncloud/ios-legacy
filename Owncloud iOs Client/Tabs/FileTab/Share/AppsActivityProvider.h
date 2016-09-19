//
//  ShareLinkActivityProvider.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 1/14/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>

@interface APCopyActivityIcon : UIActivity
- (id)initWithLink:(NSString *)sharedLink;
- (BOOL) isAppInstalled;
@property (nonatomic, strong) NSString *sharedLink;

@end


@interface APWhatsAppActivityIcon : UIActivity
- (id)initWithLink:(NSString *)sharedLink;
- (BOOL) isAppInstalled;
@property (nonatomic, strong) NSString *sharedLink;

@end
