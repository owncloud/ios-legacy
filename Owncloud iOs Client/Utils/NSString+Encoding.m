//
//  NSString+Encoding.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 11/12/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "NSString+Encoding.h"

@implementation NSString (encode)
- (NSString *)encodeString:(NSStringEncoding)encoding
{
    
    /*NSString *output = (__bridge NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self,
     NULL, (CFStringRef)@";/?:@&=$+{}<>,",
     CFStringConvertNSStringEncodingToEncoding(encoding));*/
    
    CFStringRef stringRef = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self,
                                                                    NULL, (CFStringRef)@";?@&=$+{}<>,!'*",
                                                                    CFStringConvertNSStringEncodingToEncoding(encoding));
    
    NSString *output = (NSString *)CFBridgingRelease(stringRef);
    
    
    
    
    int countCharactersAfterPercent = -1;
    
    for(int i = 0 ; i < [output length] ; i++) {
        NSString * newString = [output substringWithRange:NSMakeRange(i, 1)];
        //NSLog(@"newString: %@", newString);
        
        if(countCharactersAfterPercent>=0) {
            
            //NSLog(@"newString lowercaseString: %@", [newString lowercaseString]);
            output = [output stringByReplacingCharactersInRange:NSMakeRange(i, 1) withString:[newString lowercaseString]];
            countCharactersAfterPercent++;
        }
        
        if([newString isEqualToString:@"%"]) {
            countCharactersAfterPercent = 0;
        }
        
        if(countCharactersAfterPercent==2) {
            countCharactersAfterPercent = -1;
        }
    }
    
    NSLog(@"output: %@", output);
    
    return output;
}

@end

