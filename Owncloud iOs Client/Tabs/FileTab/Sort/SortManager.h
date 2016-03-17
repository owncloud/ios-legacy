//
//  SortManager.h
//  Owncloud iOs Client
//
//  Created by María Rodríguez on 03/03/16.
//
//

/*
 Copyright (C) 2016, ownCloud, Inc.
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
+ (NSInteger)numberOfSectionsInTableViewWithFolderList: (NSArray *)currentDirectoryArray;

// Returns the table view managed by the controller object.
+ (NSInteger)numberOfRowsInSection: (NSInteger) section withCurrentDirectoryArray:(NSArray *)currentDirectoryArray andSortedArray: (NSArray *) sortedArray needsExtraEmptyRow:(BOOL) emptyMessageRow;

// Returns the table view managed by the controller object.
+ (NSString *)titleForHeaderInTableViewSection:(NSInteger)section withCurrentDirectoryArray:(NSArray *)currentDirectoryArray andSortedArray: (NSArray *) sortedArray;

// Returns the titles for the sections for a table view.
+ (NSArray *)sectionIndexTitlesForTableView: (UITableView*) tableView WithCurrentDirectoryArray:(NSArray*)currentDirectoryArray;


/*
 * Array sorting methods
 */
//Method that sorts alphabetically array by selector
+ (NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector;

// This method sorts an array by modification Date and configure ot to be used in file list
+ (NSMutableArray*) sortByModificationDate:(NSArray*)array;

// This method creates an array to be shown in the files/folders list
+ (NSMutableArray*) getSortedArrayFromCurrentDirectoryArray:(NSArray*) currentDirectoryArray;


/*
 * DB methods
 */
+ (enumSortingType) getUserSortingType;
@property(nonatomic) UserDto* userToSort;

@end
