//
//  DPDownload.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/12/14.
//
//

#import "DPDownload.h"
#import "FFCircularProgressView.h"
#import "OCCommunication.h"
#import "DocumentPickerViewController.h"
#import "Customization.h"
#import "ManageFilesDB.h"

@implementation DPDownload

- (id) init{
    
    self = [super init];
    if (self) {
        _isLIFO = YES;
    }
    return self;
}

- (void) downloadFile:(FileDto *)file withProgressView:(FFCircularProgressView *)progressView{
    
    OCCommunication *sharedCommunication = [DocumentPickerViewController sharedOCCommunication];
    self.file = file;
    NSArray *splitedUrl = [self.user.url componentsSeparatedByString:@"/"];
    NSString *serverUrl = [NSString stringWithFormat:@"%@%@%@",[NSString stringWithFormat:@"%@/%@/%@",[splitedUrl objectAtIndex:0],[splitedUrl objectAtIndex:1],[splitedUrl objectAtIndex:2]], file.filePath, file.fileName];
    
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //get local path of server
    __block NSString *localPath;
    
    NSString *temporalFileName;
    NSString *deviceLocalPath;
    
    
    if (file.isNecessaryUpdate) {
        //Change the local name for a temporal one
        temporalFileName = [NSString stringWithFormat:@"%@-%@", [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]], [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        localPath = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, temporalFileName];
    } else {
        localPath = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    deviceLocalPath = localPath;
    
    if (!file.isNecessaryUpdate && (file.isDownload != overwriting)) {
        //Change file status in Data Base to downloading
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:downloading];
    } else if (file.isNecessaryUpdate) {
        //Change file status in Data Base to updating
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:updating];
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [sharedCommunication setCredentialsWithCookie:self.user.password];
    } else if (k_is_oauth_active) {
        [sharedCommunication setCredentialsOauthWithToken:self.user.password];
    } else {
        [sharedCommunication setCredentialsWithUser:self.user.username andPassword:self.user.password];
    }
    
    
    [progressView startSpinProgressBackgroundLayer];
    
    self.operation = [sharedCommunication downloadFile:serverUrl toDestiny:localPath withLIFOSystem:YES onCommunication:sharedCommunication progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        [progressView stopSpinProgressBackgroundLayer];
        float percent = (float)totalBytesRead / totalBytesExpectedToRead;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:percent];
        });
        
        
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:downloaded];
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [progressView setHidden:YES];
            [self.delegate downloadCompleted:file];
        });
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        [progressView stopSpinProgressBackgroundLayer];
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:notDownload];
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:0.0];
            [self.delegate downloadFailed:error.description andFile:file];
        });
   
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
       [self.delegate downloadFailed:@"" andFile:file];
    }];

}

- (void) cancelDownload{
    
    [self.operation cancel];
}

@end
