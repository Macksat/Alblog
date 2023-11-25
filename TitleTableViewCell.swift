//
//  TitleTableViewCell.swift
//  TitleTableViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit

class TitleTableViewCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.backgroundColor = .clear
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
