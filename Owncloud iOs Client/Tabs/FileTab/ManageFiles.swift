//
//  ManageFiles.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 13/07/2017.
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

@objc class ManageFiles: NSObject {
    
    
    
    func storeListOfFiles(_ listOfFiles: [FileDto] , forFileId fileId: Int, andUser user: UserDto) {
        
        //Change the filePath from the library to our db format
        
        for currentFile:FileDto in listOfFiles {
            
            currentFile.filePath = UtilsUrls.getFilePathOnDBByFilePath(onFileDto: currentFile.filePath, andUser:user)
        }
        
        
        ManageFilesDB.insertManyFiles(listOfFiles, ofFileId: fileId, andUser: user)
        
    }
    
}
