//
//  SharePrivilegeCell.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 13/1/16.
//
//

/*
Copyright (C) 2017, ownCloud GmbH.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import UIKit

class SharePrivilegeCell:UITableViewCell {
    
    @IBOutlet weak var optionSwitch: UISwitch!
    @IBOutlet weak var optionName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
