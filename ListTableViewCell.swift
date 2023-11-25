//
//  ListTableViewCell.swift
//  ListTableViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit

class ListTableViewCell: UITableViewCell {
   
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var detailButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textView.backgroundColor = .clear
        button.setTitle("", for: .normal)
        self.backgroundColor = .clear
        detailButton.setTitle("", for: .normal)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
