//
//  LinkTableViewCell.swift
//  LinkTableViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit

class LinkTableViewCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var webImageView: UIImageView!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var detailButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = .clear
        detailButton.setTitle("", for: .normal)
    }

    func setUpContents(image: UIImage, string: String) {
        DispatchQueue.main.async {
            self.webImageView.image = image
            self.webImageView.layer.cornerRadius = 10
            self.webImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            self.textField.text = string
        }
    }
}
