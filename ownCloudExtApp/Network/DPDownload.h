//
//  DPDownload.h
//  Owncloud iOs Client
//
// Simple download class based in complex download class of the core app.
// Valid for a document provider in order to download one file at time
//
//  Created by Gonzalo Gonzalez on 10/12/14.
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
#import "UserDto.h"
#import "FFCircularProgressView.h"

typedef NS_ENUM(NSInteger, downloadStateEnum) {
    downloadNotStarted = 0,
    downloadCheckingEtag = 1,
    downloadWorking = 2,
    downloadComplete = 3,
    downloadFailed = 4,
};


@protocol DPDownloadDelegate

@optional
- (void)downloadCompleted:(FileDto*)fileDto;
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto;
- (void)downloadCancelled:(FileDto*)fileDto;
@end


@interface DPDownload : NSObject

@property (nonatomic) NSInteger state;
@property(nonatomic,weak) __weak id<DPDownloadDelegate> delegate;


- (void) downloadFile:(FileDto *)file locatedInFolder:(NSString*)localFolder ofUser:(UserDto *)user withProgressView:(FFCircularProgressView *)progressView;
- (void) cancelDownload;

@end
