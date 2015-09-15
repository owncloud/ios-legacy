//
//  ShareFileCell.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/8/15.
//
//

import UIKit

class ShareFileCell: UITableViewCell {
    
    @IBOutlet weak var fileImage: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var fileSize: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
