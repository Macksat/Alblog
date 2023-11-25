//
//  GridCellViewController.swift
//  PhotoCategorizer
//
//  Created by Masayuki Sato on 2021/06/27.
//

import UIKit
import Photos

class GridCellViewController: UICollectionViewCell {
    
    public var requestID: PHImageRequestID?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.layer.cornerRadius = 10
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.isHidden = false
        imageView.image = nil
    }

    func setUpContents(image: UIImage, string: String) {
        DispatchQueue.main.async {
            if image == UIImage() {
                self.imageView.isHidden = true
            }
            self.imageView.image = image
            self.label.text = string
        }
    }
}
