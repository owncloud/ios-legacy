//
//  ManageDownloads.h
//  Owncloud iOs Client
//
// This class manage the array of downloads objects
// in order to download as a FIFO list.
//
//
//  Created by Gonzalo Gonzalez on 14/08/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import <Foundation/Foundation.h>
#import "Download.h"


@interface ManageDownloads : NSObject <DownloadDelegate>


+(ManageDownloads *)singleton;


- (void) cancelDownloads;

- (void) cancelDownloadsAndRefreshInterface;

- (NSArray *) getDownloads;

- (void) addDownload:(Download *)download;

- (void) addSimpleDownload:(Download *)download;

- (void) removeDownload:(Download *)download;

- (void) changeBehaviourForBackgroundFetch:(BOOL)enter;

@end
