 //
//  InfoFileUtils.m
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 06/03/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "InfoFileUtils.h"

@implementation InfoFileUtils


///-----------------------------------
/// @name getTheDifferenceBetweenDateOfUploadAndNow
///-----------------------------------

/**
 * This method obtains the difference between the upload date and the received date doing
 * a custom string like a:
 * seconds ago
 * minutes ago
 * hours ago
 * days ago
 * the date of upload (When the days > 30)
 *
 * @param NSDate -> date
 *
 * @return NSString -> The searched date
 */
+ (NSString *)getTheDifferenceBetweenDateOfUploadAndNow:(NSDate *)date {
    
    NSString *temp;
    
    NSDate *now = [NSDate date];
    NSTimeInterval timePassed = [now timeIntervalSinceDate:date];
    
    int minute = 60; //seconds one minute
    int hour = 3600; //seconds one hour
    int day = 86400; //seconds one day
    int month = 2592000; //seconds one month of 30 days
    int year = 31536000; //seconds in one year
    
    if (timePassed > 0) {
        
        if (timePassed < minute ) {
            //seconds ago
            temp=[NSString stringWithFormat:NSLocalizedString(@"recent_now", nil)];
        } else if (timePassed < hour) {
            //minutes ago
            int minutes;
            minutes = timePassed/minute;
            NSString *minutesString = [NSString stringWithFormat:@"%d", minutes];
            if (minutes == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_minute", nil) stringByReplacingOccurrencesOfString:@"$minutes" withString:minutesString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_minutes", nil) stringByReplacingOccurrencesOfString:@"$minutes" withString:minutesString]];
            }
            
        } else if (timePassed < day) {
            //hours ago
            int hours;
            hours = timePassed/hour;
            NSString *hoursString = [NSString stringWithFormat:@"%d", hours];
            if (hours == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_hour", nil) stringByReplacingOccurrencesOfString:@"$hours" withString:hoursString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_hours", nil) stringByReplacingOccurrencesOfString:@"$hours" withString:hoursString]];
            }
            
        } else if (timePassed < month) {
            //days ago
            int days;
            days = timePassed/day;
            NSString *daysString = [NSString stringWithFormat:@"%d", days];
            if (days == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_day", nil) stringByReplacingOccurrencesOfString:@"$days" withString:daysString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_days", nil) stringByReplacingOccurrencesOfString:@"$days" withString:daysString]];
            }
            
        } else if (timePassed < year) {
            //months ago
            int months;
            months = timePassed/month;
            NSString *monthsString = [NSString stringWithFormat:@"%d", months];
            if (months == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_month", nil) stringByReplacingOccurrencesOfString:@"$months" withString:monthsString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_months", nil) stringByReplacingOccurrencesOfString:@"$months" withString:monthsString]];
            }
        } else {
            //years ago -> the day 13-12-12
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            //Set the date and time format as the system
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeZone:[NSTimeZone systemTimeZone]];
            temp = [formatter stringFromDate:date];
        }
        
    } else {
        //If the timePassed is negative because the device date is previous to the upload date, show the date not the relative date
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        //Set the date and time format as the system
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setDateFormat:@"dd/MM/yy"];
        temp = [formatter stringFromDate:date];
    }
    return temp;
}

@end
