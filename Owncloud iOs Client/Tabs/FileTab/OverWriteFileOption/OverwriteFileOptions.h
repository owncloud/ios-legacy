//
//  OverwriteFileOptions.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 3/18/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "FileDto.h"

@protocol OverwriteFileOptionsDelegate
@optional
- (void)setNewNameToSaveFile:(NSString *) name;
- (void)overWriteFile;
@end

@interface OverwriteFileOptions : NSObject <UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate> {
}

@property(nonatomic,strong)UIActionSheet *overwriteOptionsActionSheet;
@property(nonatomic,strong)UIView *viewToShow;
@property(nonatomic,strong)UIAlertView *renameAlertView;
@property(nonatomic,weak) __weak id<OverwriteFileOptionsDelegate> delegate;
@property(nonatomic,strong) FileDto *fileDto;


-(void) showOverWriteOptionActionSheet;



@end
