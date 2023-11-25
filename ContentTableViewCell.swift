//
//  ContentTableViewCell.swift
//  PhotoCategorizer
//
//  Created by Sato Masayuki on 2021/10/19.
//

import UIKit

class ContentTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBAction func moreButton(_ sender: Any) {
    }
    @IBOutlet weak var collectionView: UICollectionView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        collectionView.register(UINib(nibName: "AlbumCellViewController", bundle: nil), forCellWithReuseIdentifier: "AlbumCellViewController")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCollectionDelegateDataSource<D: UICollectionViewDelegate & UICollectionViewDataSource>(dataSourceDelegate: D, forRow row: Int) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.reloadData()
    }
    
    func setUpContents(string: String) {
        title.text = string
    }
}
