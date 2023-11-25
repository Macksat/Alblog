//
//  TextCollectionViewCell.swift
//  TextCollectionViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit

class TextCollectionViewCell: UICollectionViewCell {
    
    let ud = UserDefaults.standard

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var title: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textView.layer.cornerRadius = 10
        title.layer.cornerRadius = 10
        textView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        title.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        textView.backgroundColor = .systemGray6
        title.backgroundColor = .systemGray6
        deleteButton.setTitle("", for: .normal)
    }
}
