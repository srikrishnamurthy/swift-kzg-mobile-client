//
//  VerifyTableViewCell.swift
//  srsly
//
//  Created by aang on 1/29/23.
//

import UIKit

class VerifyTableViewCell: UITableViewCell {
    
    static let identifier = "VerifyTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "VerifyTableViewCell", bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
