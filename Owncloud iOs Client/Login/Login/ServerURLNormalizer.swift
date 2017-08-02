//
//  ServerURLNormalizer.swift
//  Owncloud iOs Client
//
//  Created by David A. Velasco on 19/7/17.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

import Foundation


class ServerURLNormalizer {
    
    let k_http_prefix : String = "http://"
    let k_https_prefix : String = "https://"
    let k_remove_to_suffix : String = "/index.php"
    let k_remove_to_contained_path : String = "/index.php/apps/"
    
    var normalizedURL = ""
    var user: String?
    var password: String?
    var scheme: String? //TODO store scheme
    
    func normalize(serverURL: String) {
        
        self.normalizedURL = serverURL;
        
        self.normalizedURL = stripAccidentalWhiteSpaces(inputURL: normalizedURL)
        
        self.normalizedURL = stripUsernameAndPassword(inputURL: normalizedURL)
        
        self.normalizedURL = stripIndexPhpOrAppsFilesFromUrl(inputURL: normalizedURL);
        
        self.normalizedURL = grantFinalSlash(inputURL: normalizedURL)
    }
    
    // Strip accidental white spaces at the end and beginning of the received URL.
    //
    func stripAccidentalWhiteSpaces(inputURL: String) -> String {
        
        var workURL: String = inputURL;
        
        while(workURL.hasSuffix(" ")) {   // final blanks
            workURL = workURL.substring(to: workURL.index(before: workURL.endIndex))
        }
    
        while(workURL.hasPrefix(" ")) { // initial blanks
            workURL = workURL.substring(from: workURL.index(after: workURL.startIndex))
        }
        
        return workURL
    }
    
    
    // Strip username and password inserted in the received URL, if any.
    //
    // Stores both values in 'user' and 'password' properties.
    //
    func stripUsernameAndPassword(inputURL: String) -> String {
        
        var workURL: String = inputURL;

        // inputURL without scheme prefix is accepted, but NSURLComponents will parse all the string as the scheme
        var forcedPrefix = false;
        if !(workURL.hasPrefix(k_https_prefix) || workURL.hasPrefix(k_http_prefix)) {
            // add HTTPS as prefix to trick NSURLComponents
            workURL = "\(k_https_prefix)\(workURL)"
            forcedPrefix = true;
        }
        if let components = NSURLComponents(string: workURL) {
            // save parsed user and password
            self.user = components.user
            self.password = components.password

            // generate the URL as string again, without user and password
            components.user = nil;
            components.password = nil;
            workURL = components.string!
            
            // remove scheme if was not in inputURL
            if forcedPrefix {
                workURL = workURL.substring(from: workURL.range(of: k_https_prefix)!.upperBound)
            }
            
            return workURL
            
        } else {
            return inputURL
        }
    }
    
    
    // Strip accepted paths for URLs copied directly from web browser
    //
    func stripIndexPhpOrAppsFilesFromUrl(inputURL: String) -> String {
        
        var returnURL: String = inputURL
        
        if inputURL.hasSuffix(k_remove_to_suffix) {
            
            returnURL = inputURL.substring(to: inputURL.range(of: k_remove_to_suffix, options: NSString.CompareOptions.backwards)!.lowerBound)
            
        } else if let rangeOfContainedPathToRemove = inputURL.range(of: k_remove_to_contained_path) {
            
            returnURL = inputURL.substring(to: rangeOfContainedPathToRemove.lowerBound);
        }
        
        return returnURL
    }
    
    
    // Grant last character is /
    //
    func grantFinalSlash(inputURL: String) -> String {
        
        if !inputURL.hasSuffix("/") {
            return "\(inputURL)/"
        }
        
        return inputURL
    }
    
}
