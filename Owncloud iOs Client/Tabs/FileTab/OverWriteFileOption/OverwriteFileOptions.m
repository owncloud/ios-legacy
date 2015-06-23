//
//  OverwriteFileOptions.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 3/18/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OverwriteFileOptions.h"
#import "FileNameUtils.h"
#import "UserDto.h"
#import "ManageUsersDB.h"

@implementation OverwriteFileOptions


-(void) showOverWriteOptionActionSheet {
    
    NSString *titleMessage;
    
    if(self.fileDto.isDirectory) {
        titleMessage = NSLocalizedString(@"folder_exist", nil);
    } else {
        titleMessage = NSLocalizedString(@"file_exist", nil);
    }
    
    self.overwriteOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:titleMessage/*@"\r\n\r\n"*/ delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:NSLocalizedString(@"overwritte_title", nil) otherButtonTitles:NSLocalizedString(@"rename_long_press", nil), nil];
    
    [self.overwriteOptionsActionSheet showInView:self.viewToShow];
    
    //Now this code is not in use. We are using the standard iOs title in UIActionSheet
    
  /*  CGRect oldFrame = [(UILabel*)[[self.overwriteOptionsActionSheet subviews] objectAtIndex:0] frame];
    oldFrame.size.height = 50;
    oldFrame.size.width = oldFrame.size.width - 20 ; //To quit the borders
    oldFrame.origin.x = oldFrame.origin.x + 10;
    UILabel *newTitle = [[UILabel alloc] initWithFrame:oldFrame];
    newTitle.font = [UIFont boldSystemFontOfSize:17];
    newTitle.numberOfLines = 2;
    newTitle.textAlignment = NSTextAlignmentCenter;
    newTitle.backgroundColor = [UIColor clearColor];
    
    newTitle.textColor = [UIColor blackColor];
    
    
    newTitle.text = titleMessage;
    [self.overwriteOptionsActionSheet addSubview:newTitle];*/

}


#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            DLog(@"overwritte_title");
            [self.delegate overWriteFile];
            break;
        case 1:
        
            DLog(@"rename_long_press");
            
            _renameAlertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"rename_file_title", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"save", nil), nil];
            _renameAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [_renameAlertView textFieldAtIndex:0].delegate = self;
            [[_renameAlertView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
            [[_renameAlertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            
            if(self.fileDto.isDirectory) {
                if ( [self.fileDto.fileName length] > 0) {
                    [_renameAlertView textFieldAtIndex:0].text = [[self.fileDto.fileName substringToIndex:[self.fileDto.fileName length] - 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
            } else {
                 [_renameAlertView textFieldAtIndex:0].text = [self.fileDto.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
            [_renameAlertView show];
            
            [self performSelector:@selector(markFileName) withObject:nil afterDelay:0.5];
            
            break;
        case 2:
            DLog(@"cancel");
            break;
    }
}

- (void)markFileName{
    
    //Check if the filename have extension and is not a directory
    if(([[_renameAlertView textFieldAtIndex:0].text rangeOfString:@"."].location != NSNotFound) && !self.fileDto.isDirectory) {
        [FileNameUtils markFileNameOnAlertView:[_renameAlertView textFieldAtIndex:0]];
    }
}

#pragma mark - UIAlertViewDelegate
- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex {
    // Save
    if( buttonIndex == 1 ) {
        
        BOOL serverHasForbiddenCharactersSupport = [ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport];
        
        if (![FileNameUtils isForbiddenCharactersInFileName:[_renameAlertView textFieldAtIndex:0].text withForbiddenCharactersSupported:serverHasForbiddenCharactersSupport]) {
            //Character recognize
            
            //Clear the spaces of the left and the right of the sentence
            NSString* result = [[_renameAlertView textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if ([FileNameUtils isForbiddenCharactersInFileName:result withForbiddenCharactersSupported:serverHasForbiddenCharactersSupport]) {
                
                NSString *msg = nil;
                msg = NSLocalizedString(@"forbidden_characters_from_server", nil);

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg
                                                                message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alert show];
            } else {
                if(self.fileDto.isDirectory) {
                    [self.delegate setNewNameToSaveFile:[result stringByAppendingString:@"/"]];
                } else {
                    [self.delegate setNewNameToSaveFile:result];
                }
            }
        } else {
            //Characters forbidden
            DLog(@"The name has problematic characters");
            
            if (_fileDto.isDirectory) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"forbidden_characters_from_server", nil) message:@"" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"forbidden_characters_from_server", nil) message:@"" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
            }
        }
        
        
    } else if (buttonIndex == 0) {
        //Cancel
    } else {
        //Nothing
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    BOOL output = YES;
    
    NSString *stringNow = [alertView textFieldAtIndex:0].text;
    
    
    //Active button of folderview only when the textfield has something.
    NSString *rawString = stringNow;
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
    
    if ([trimmed length] == 0) {
        // Text was empty or only whitespace.
        output = NO;
    }
    
    //Button save disable when the textfield is empty
    if ([stringNow isEqualToString:@""]) {
        output = NO;
    }
    
    return output;
}


@end
