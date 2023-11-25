//
//  CustomTableViewCell.swift
//  PhotoCategorizer
//
//  Created by Masayuki Sato on 2021/07/03.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var moreButton: UIButton!
    @IBAction func moreButton(_ sender: Any) {
    }
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Do any additional setup after loading the view.
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        collectionView.register(UINib(nibName: "AlbumCellViewController", bundle: nil), forCellWithReuseIdentifier: "AlbumCellViewController")
    }

    func setCollectionDelegateDataSource<D: UICollectionViewDelegate & UICollectionViewDataSource>(dataSourceDelegate: D, forRow row: Int) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.reloadData()
    }
    
    func setUpContents(string: String) {
        label.text = string
    }
}
