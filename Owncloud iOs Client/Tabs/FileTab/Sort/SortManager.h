//
//  SortManager.h
//  Owncloud iOs Client
//
//  Created by María Rodríguez on 03/03/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#ifndef SortManager_h
#define SortManager_h


#endif /* SortManager_h */

#import <Foundation/Foundation.h>
#import "ManageUsersDB.h"

@interface SortManager: NSObject

/*
 * TableViews methods
 */

// Returns the number of sections in a table view depending on the user.
+ (NSInteger)numberOfSectionsInTableViewForUser:(UserDto*)user withFolderList: (NSArray *)currentDirectoryArray;

// Returns the number of rows in a table viewn for an user depending on the sorting method and section.
+ (NSInteger)numberOfRowsInSection: (NSInteger) section forUser:(UserDto*)user withCurrentDirectoryArray:(NSArray *)currentDirectoryArray andSortedArray: (NSArray *) sortedArray needsExtraEmptyRow:(BOOL) emptyMessageRow;

// Returns the table header title for each section.
+ (NSString *)titleForHeaderInTableViewSection:(NSInteger)section forUser:(UserDto*)user withCurrentDirectoryArray:(NSArray *)currentDirectoryArray andSortedArray: (NSArray *) sortedArray;

// Returns the titles for the sections for a table view.
+ (NSArray *)sectionIndexTitlesForTableView: (UITableView*) tableView forUser:(UserDto*)user withCurrentDirectoryArray:(NSArray*)currentDirectoryArray;


/*
 * Array sorting methods
 */

// This method sorts alphabetically an array by selector
+ (NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector;

// This method sorts an array by modification date to be shown in files/folders list
+ (NSMutableArray*) sortByModificationDate:(NSArray*)array;

// This method creates an array to be shown in the files/folders list
+ (NSMutableArray*) getSortedArrayFromCurrentDirectoryArray:(NSArray*) currentDirectoryArray forUser:(UserDto*)user;


@end
