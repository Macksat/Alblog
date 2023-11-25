//
//  ImageCollectionViewCell.swift
//  PhotoCategorizer
//
//  Created by Sato Masayuki on 2021/10/30.
//

import UIKit
import Photos

class ImageCollectionViewCell: UICollectionViewCell {
    
    public var requestID: PHImageRequestID?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageView.layer.cornerRadius = 10
        deleteButton.setTitle("", for: .normal)
        deleteButton.setImage(UIImage(), for: .normal)
        deleteButton.isUserInteractionEnabled = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.isHidden = false
        imageView.image = nil
    }
}
