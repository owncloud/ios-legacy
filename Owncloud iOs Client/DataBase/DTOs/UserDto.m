//
//  UserDto.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/18/12.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UserDto.h"

@implementation UserDto

#pragma mark - NSCopying

-(id) copyWithZone:(NSZone *)zone {
    UserDto *userCopy = [[UserDto alloc]init];
    userCopy.userId = self.userId;
    userCopy.url = self.url;
    userCopy.username = self.username;
    userCopy.credDto = self.credDto;
    userCopy.ssl = self.ssl;
    userCopy.activeaccount = self.activeaccount;
    userCopy.storageOccupied = self.storageOccupied;
    userCopy.storage = self.storage;
    userCopy.hasShareApiSupport = self.hasShareApiSupport;
    userCopy.hasShareeApiSupport = self.hasShareeApiSupport;
    userCopy.hasCookiesSupport = self.hasCookiesSupport;
    userCopy.hasForbiddenCharactersSupport = self.hasForbiddenCharactersSupport;
    userCopy.hasCapabilitiesSupport = self.hasCapabilitiesSupport;
    userCopy.hasFedSharesOptionShareSupport = self.hasFedSharesOptionShareSupport;
    userCopy.hasPublicShareLinkOptionNameSupport = self.hasPublicShareLinkOptionNameSupport;
    userCopy.hasPublicShareLinkOptionUploadOnlySupport = self.hasPublicShareLinkOptionUploadOnlySupport;
    userCopy.imageInstantUpload = self.imageInstantUpload;
    userCopy.videoInstantUpload = self.videoInstantUpload;
    userCopy.backgroundInstantUpload = self.backgroundInstantUpload;
    userCopy.pathInstantUpload = self.pathInstantUpload;
    userCopy.onlyWifiInstantUpload = self.onlyWifiInstantUpload;
    userCopy.timestampInstantUploadImage = self.timestampInstantUploadImage;
    userCopy.timestampInstantUploadImage = self.timestampInstantUploadVideo;
    userCopy.urlRedirected = self.urlRedirected;
    userCopy.capabilitiesDto = self.capabilitiesDto;
    userCopy.sortingType = self.sortingType;
    userCopy.predefinedUrl = self.predefinedUrl;
    
    return userCopy;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:self.userId  forKey:@"userId"];
    [coder encodeObject:self.url forKey:@"url"];
    [coder encodeObject:self.username forKey:@"username"];
    [coder encodeObject:self.credDto  forKey:@"credDto"];
    [coder encodeBool:self.ssl forKey:@"ssl"];
    [coder encodeBool:self.activeaccount forKey:@"activeaccount"];
    [coder encodeDouble:self.storageOccupied forKey:@"storageOccupied"];
    [coder encodeDouble:self.storage forKey:@"storage"];
    [coder encodeInteger:self.hasShareApiSupport  forKey:@"hasShareApiSupport"];
    [coder encodeInteger:self.hasShareeApiSupport  forKey:@"hasShareeApiSupport"];
    [coder encodeInteger:self.hasCookiesSupport  forKey:@"hasCookiesSupport"];
    [coder encodeInteger:self.hasForbiddenCharactersSupport  forKey:@"hasForbiddenCharactersSupport"];
    [coder encodeInteger:self.hasCapabilitiesSupport  forKey:@"hasCapabilitiesSupport"];
    [coder encodeInteger:self.hasFedSharesOptionShareSupport  forKey:@"hasFedSharesOptionShareSupport"];
    [coder encodeInteger:self.hasPublicShareLinkOptionNameSupport  forKey:@"hasPublicShareLinkOptionNameSupport"];
    [coder encodeInteger:self.hasPublicShareLinkOptionUploadOnlySupport  forKey:@"hasPublicShareLinkOptionUploadOnlySupport"];
    [coder encodeBool:self.imageInstantUpload  forKey:@"imageInstantUpload"];
    [coder encodeBool:self.videoInstantUpload  forKey:@"videoInstantUpload"];
    [coder encodeBool:self.backgroundInstantUpload  forKey:@"backgroundInstantUpload"];
    [coder encodeObject:self.pathInstantUpload  forKey:@"pathInstantUpload"];
    [coder encodeBool:self.onlyWifiInstantUpload  forKey:@"onlyWifiInstantUpload"];
    [coder encodeDouble:self.timestampInstantUploadImage forKey:@"timestampInstantUploadImage"];
    [coder encodeDouble:self.timestampInstantUploadVideo forKey:@"timestampInstantUploadVideo"];
    [coder encodeObject:self.urlRedirected  forKey:@"urlRedirected"];
    [coder encodeObject:self.capabilitiesDto  forKey:@"capabilitiesDto"];
    [coder encodeInteger:self.sortingType  forKey:@"sortingType"];
    [coder encodeObject:self.predefinedUrl  forKey:@"predefinedUrl"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.userId = [decoder decodeIntegerForKey:@"userId"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.username = [decoder decodeObjectForKey:@"username"];
        self.credDto = [decoder decodeObjectForKey:@"credDto"];
        self.ssl = [decoder decodeBoolForKey:@"sll"];
        self.activeaccount = [decoder decodeBoolForKey:@"activeaccount"];
        self.storageOccupied = [decoder decodeDoubleForKey:@"storageOccupied"];
        self.storage = [decoder decodeDoubleForKey:@"storage"];
        self.hasShareApiSupport = [decoder decodeIntegerForKey:@"hasShareApiSupport"];
        self.hasShareeApiSupport = [decoder decodeIntegerForKey:@"hasShareeApiSupport"];
        self.hasCookiesSupport = [decoder decodeIntegerForKey:@"hasCookiesSupport"];
        self.hasForbiddenCharactersSupport = [decoder decodeIntegerForKey:@"hasForbiddenCharactersSupport"];
        self.hasCapabilitiesSupport = [decoder decodeIntegerForKey:@"hasCapabilitiesSupport"];
        self.hasFedSharesOptionShareSupport = [decoder decodeIntegerForKey:@"hasFedSharesOptionShareSupport"];
        self.hasPublicShareLinkOptionNameSupport = [decoder decodeIntegerForKey:@"hasPublicShareLinkOptionNameSupport"];
        self.hasPublicShareLinkOptionUploadOnlySupport = [decoder decodeIntegerForKey:@"hasPublicShareLinkOptionUploadOnlySupport"];
        self.imageInstantUpload = [decoder decodeBoolForKey:@"imageInstantUpload"];
        self.videoInstantUpload = [decoder decodeBoolForKey:@"videoInstantUpload"];
        self.backgroundInstantUpload = [decoder decodeBoolForKey:@"backgroundInstantUpload"];
        self.pathInstantUpload = [decoder decodeObjectForKey:@"pathInstantUpload"];
        self.onlyWifiInstantUpload = [decoder decodeBoolForKey:@"onlyWifiInstantUpload"];
        self.timestampInstantUploadImage = [decoder decodeDoubleForKey:@"timestampInstantUploadImage"];
        self.timestampInstantUploadVideo = [decoder decodeDoubleForKey:@"timestampInstantUploadVideo"];
        self.urlRedirected = [decoder decodeObjectForKey:@"urlRedirected"];
        self.capabilitiesDto = [decoder decodeObjectForKey:@"capabilitiesDto"];
        self.sortingType = [decoder decodeIntegerForKey:@"sortingType"];
        self.predefinedUrl = [decoder decodeObjectForKey:@"predefinedUrl"];
    }
    return self;
}



- (NSString *) nameToDisplay {
    
    if (self.credDto.userDisplayName == nil || [self.credDto.userDisplayName isEqualToString:@""]) {
        
        return self.credDto.userName;
        
    } else {
        
        return self.credDto.userDisplayName;
    }
}

@end
