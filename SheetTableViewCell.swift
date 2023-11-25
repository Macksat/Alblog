//
//  SheetTableViewCell.swift
//  SheetTableViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit

class SheetTableViewCell: UITableViewCell {
    
    @IBOutlet weak var textView2Height: NSLayoutConstraint!
    @IBOutlet weak var textView1Height: NSLayoutConstraint!
    @IBOutlet weak var textView1: UITextView!
    @IBOutlet weak var textView2: UITextView!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var detailButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textView1.layer.borderColor = UIColor.gray.cgColor
        textView2.layer.borderColor = UIColor.gray.cgColor
        textView1.layer.borderWidth = 0.2
        textView2.layer.borderWidth = 0.2
        self.backgroundColor = .clear
        detailButton.setTitle("", for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
