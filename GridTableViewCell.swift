//
//  GridTableViewCell.swift
//  GridTableViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit
import RealmSwift

class GridTableViewCell: UITableViewCell {
    
    let ud = UserDefaults.standard
    let realm = try! Realm()

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var detailButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        detailButton.setTitle("", for: .normal)
        collectionView.register(UINib(nibName: "TextCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TextCollectionViewCell")
        self.backgroundColor = .clear
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
}
