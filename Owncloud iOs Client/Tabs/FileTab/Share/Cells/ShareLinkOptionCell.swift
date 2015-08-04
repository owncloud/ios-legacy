//
//  ShareLinkOptionCell.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/8/15.
//
//

import UIKit

class ShareLinkOptionCell: UITableViewCell {
    
     @IBOutlet weak var optionSwith: UISwitch!
     @IBOutlet weak var optionName: UILabel!
     @IBOutlet weak var optionDetail: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
