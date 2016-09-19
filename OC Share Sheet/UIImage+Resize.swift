//
//  UIImage+Resize.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 26/3/15.
//

/*
Copyright (C) 2016, ownCloud GmbH.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import Foundation

extension UIImage {
    public func resize(_ size:CGSize, completionHandler:@escaping (_ resizedImage:UIImage, _ data:Data)->()) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
            let newSize:CGSize = size
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let imageData = UIImageJPEGRepresentation(newImage!, 0.5)
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(newImage!, imageData!)
            })
        })
    }
}
