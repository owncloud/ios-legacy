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

/*
 * Class to interact with the app-level trust store. 
 *
 * Allows to check if an X509 server certificate contained in an NSURLAuthenticationChallenge is already contained 
 * in the trust store or not, and add it to the trust store later. This should be done only after the user explicilty
 * approved it.
 */
@interface SSLCertificateManager : NSObject <NSURLSessionDelegate, UIAlertViewDelegate, NSURLSessionTaskDelegate>

/*
 * Checks if the challenge passed as a parameter corresponds to server certificate not trusted by iOS system, 
 * and if it is trusted by the user anyway, searching for it in the app-level store of certificates that 
 * were previously approved by her.
 *
 * As a SIDE EFFECT, the server certificate in the challenge becomes the CURRENT certificate.
 */
- (BOOL) isTrustedServerCertificateIn:(NSURLAuthenticationChallenge *) challenge;

/*
 * Checks if the CURRENT certificate (i.e: the last certificate that was passed to the method isTrustedServerCertificateIn)
 * is contained in the app-level store of certificates approved previously by the user.
 */
- (BOOL) isCurrentCertificateTrusted;

/*
 * Adds the CURRENT certificate (i.e: the last certificate that was passed to the method isTrustedServerCertificateIn)
 * to the app-level store of certificates approved by the user, so that any request about trust on the same certificate
 * via isTrustedServerCertificateIn or isCurrentCertificateTrusted will return 'YES'.
 */
- (void) trustCurrentCertificate;

/*
 * Helper method to check if a given NSError corresponds to a server certificate not trusted by iOS
 */
- (BOOL) isUntrustedServerCertificate:(NSError*) error;

@end


#endif /* SSLCertificateManager_h */
