//
//  ShareLoadingCell.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 2/10/15.
//
//

import UIKit

class ShareLoadingCell: UITableViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
