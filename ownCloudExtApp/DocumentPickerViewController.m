//
//  DocumentPickerViewController.m
//  ownCloudExtApp
//
//  Created by Gonzalo Gonzalez on 14/10/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DocumentPickerViewController.h"
#import "OCKeychain.h"
#import "CredentialsDto.h"

@interface DocumentPickerViewController ()

@end

@implementation DocumentPickerViewController

- (IBAction)openDocument:(id)sender {
    NSURL* documentURL = [self.documentStorageURL URLByAppendingPathComponent:@"Untitled.txt"];
    
    // TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
    [self dismissGrantingAccessToURL:documentURL];
}

-(void)prepareForPresentationInMode:(UIDocumentPickerMode)mode {
    // TODO: present a view controller appropriate for picker mode here
}

@end
