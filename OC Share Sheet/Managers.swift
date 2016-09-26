//
//  Managers.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/3/15.
//

/*
Copyright (C) 2016, ownCloud GmbH.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import UIKit

class Managers: NSObject {

    //MARK: FMDatabaseQueue
    class var sharedDatabase: FMDatabaseQueue {
       struct Static {
        static let sharedDatabase: FMDatabaseQueue = FMDatabaseQueue(path:((UtilsUrls.getOwnCloudFilePath()).appending("DB.sqlite")), flags: SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FILEPROTECTION_NONE)
        }

        return Static.sharedDatabase
    }
    
    
    //MARK: OCCommunication
    class var sharedOCCommunication: OCCommunication {
        struct Static {
            static let sharedOCCommunication: OCCommunication = OCCommunication()
        }
        
        return Static.sharedOCCommunication
    }
}






