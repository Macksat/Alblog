//
//  MemoTableViewCell.swift
//  MemoTableViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit

class MemoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var detailButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 10
        detailButton.setTitle("", for: .normal)
        self.backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textView.text = ""
    }
}
