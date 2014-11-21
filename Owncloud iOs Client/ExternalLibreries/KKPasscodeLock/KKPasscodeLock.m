//
// Copyright 2011-2012 Kosher Penguin LLC
// Created by Adar Porat (https://github.com/aporat) on 1/16/2012.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "KKPasscodeLock.h"
#import "KKKeychain.h"
#import "KKPasscodeViewController.h"

CGFloat const kPasscodeBlockDisabled = MAXFLOAT;

static KKPasscodeLock *sharedLock = nil;

@interface KKPasscodeLock ()

@property (nonatomic, strong, readwrite) NSDateFormatter *dateFormatter;

@end

@implementation KKPasscodeLock

@synthesize eraseOption = _eraseOption;
@synthesize attemptsAllowed = _attemptsAllowed;
@synthesize passcodeBlockInterval = _passcodeBlockInterval;

+ (KKPasscodeLock*)sharedLock
{
	@synchronized(self) {
		if (sharedLock == nil) {
			sharedLock = [[self alloc] init];
			sharedLock.eraseOption = YES;
			sharedLock.attemptsAllowed = 5;
            sharedLock.passcodeBlockInterval = 600.0f; // 10 minutes default,  kPasscodeBlockDisabled means disabled
		}
	}
	return sharedLock;
}

- (void)setPasscodeBlockInterval:(NSTimeInterval)passcodeBlockInterval
{
    _passcodeBlockInterval = passcodeBlockInterval;
    if (_passcodeBlockInterval == kPasscodeBlockDisabled) {
        [KKKeychain setString:[self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]] forKey:@"incorrect_passcode_datetime"];
    }
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    }
    return _dateFormatter;
}

- (BOOL)isPasscodeRequired
{
	return [[KKKeychain getStringForKey:@"passcode_on"] isEqualToString:@"YES"];
}

- (BOOL)isPasscodeBlocked
{
    return [self passcodeBlockedRemainingTime] > 0.0f;
}

- (NSTimeInterval)passcodeBlockedRemainingTime
{
    if (self.passcodeBlockInterval == kPasscodeBlockDisabled) {
        return 0.0f; // Disabled, we don't need to check
    } else {
        NSString *lastPasscodeLock = [KKKeychain getStringForKey:@"incorrect_passcode_datetime"];
        
        NSDate *lastPasscodeLockDate = lastPasscodeLock.length ? [self.dateFormatter dateFromString:lastPasscodeLock] : nil;
        
        if (lastPasscodeLockDate) {
            return self.passcodeBlockInterval - [[NSDate date] timeIntervalSinceDate:lastPasscodeLockDate];
        } else {
            return 0.0f; // Passcode is not blocked
        }
    }
}

- (void)setDefaultSettings
{
	if (![KKKeychain getStringForKey:@"passcode_on"]) {
		[KKKeychain setString:@"NO" forKey:@"passcode_on"];
	}
	
	if (![KKKeychain getStringForKey:@"erase_data_on"]) {
		[KKKeychain setString:@"NO" forKey:@"erase_data_on"];
	}
    
    if (![KKKeychain getStringForKey:@"failedAttemptsCount"]) {
		[KKKeychain setString:@"0" forKey:@"failedAttemptsCount"];
	}
    
    if (![KKKeychain getStringForKey:@"incorrect_passcode_datetime"]) {
		[KKKeychain setString:[self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]] forKey:@"incorrect_passcode_datetime"];
	}
}

- (void)resetSettings
{
    [KKKeychain setString:@"NO" forKey:@"passcode_on"];
    [KKKeychain setString:@"NO" forKey:@"erase_data_on"];
    [KKKeychain setString:@"0" forKey:@"failedAttemptsCount"];
    [KKKeychain setString:[self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]] forKey:@"incorrect_passcode_datetime"];
}

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value
{
    static NSBundle *bundle = nil;
    if (bundle == nil)
    {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"KKPasscodeLock" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
    }
    
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}



@end
