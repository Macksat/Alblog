//
//  AlbumCellViewController.swift
//  AlbumCellViewController
//
//  Created by Sato Masayuki on 2021/08/24.
//

import UIKit
import Photos

class AlbumCellViewController: UICollectionViewCell {
    
    public var req1: PHImageRequestID?
    public var req2: PHImageRequestID?
    public var req3: PHImageRequestID?

    @IBOutlet weak var albumView: UIView!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView1Width: NSLayoutConstraint!
    @IBOutlet weak var imageView1Height: NSLayoutConstraint!
    @IBOutlet weak var imageView2Height: NSLayoutConstraint!
    @IBOutlet weak var imageView2Width: NSLayoutConstraint!
    @IBOutlet weak var imageView3Height: NSLayoutConstraint!
    @IBOutlet weak var imageView3Width: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.imageView1.layer.cornerRadius = 10
        self.imageView2.layer.cornerRadius = 10
        self.imageView3.layer.cornerRadius = 10
        self.imageView1.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        self.imageView2.layer.maskedCorners = [.layerMaxXMinYCorner]
        self.imageView3.layer.maskedCorners = [.layerMaxXMaxYCorner]
    }
    
    override func prepareForReuse() {
        imageView1.isHidden = false
        imageView2.isHidden = false
        imageView3.isHidden = false
    }

    func setUpContents(image1: UIImage, image2: UIImage, image3: UIImage, string: String) {
        DispatchQueue.main.async {
            if image1 == UIImage() {
                self.imageView1.isHidden = true
                self.imageView2.isHidden = true
                self.imageView3.isHidden = true
            }
            self.imageView1.image = image1
            self.imageView2.image = image2
            self.imageView3.image = image3
            if self.imageView2.image == nil {
                self.imageView2.backgroundColor = .systemGray4
            }
            if self.imageView3.image == nil {
                self.imageView3.backgroundColor = .systemGray5
            }
            self.label.text = string
        }
    }
}
