//
//  SSLCertificateManager.h
//  Owncloud iOs Client
//
//  Created by David A. Velasco on 29/8/17.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#ifndef SSLCertificateManager_h
#define SSLCertificateManager_h

@interface SSLCertificateManager : NSObject <NSURLSessionDelegate, UIAlertViewDelegate, NSURLSessionTaskDelegate>

- (BOOL) isUntrustedServerCertificate:(NSError*) error;

- (BOOL) isTrustedServerCertificateIn:(NSURLAuthenticationChallenge *) challenge;
- (BOOL) isCurrentCertificateTrusted;

- (void) acceptCurrentCertificate;

/*
- (void) saveCertificate:(SecTrustRef) trust withName:(NSString *) certName;
 */

@end


#endif /* SSLCertificateManager_h */
