//
//  FavoritePhotosViewController.swift
//  FavoritePhotosViewController
//
//  Created by Sato Masayuki on 2021/10/14.
//

import UIKit
import Photos

class FavoritePhotosViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var imageManager = PHImageManager()
    let ud = UserDefaults.standard

    @IBOutlet weak var detailButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBAction func detailButton(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ((self.view.frame.width)/2) - 25, height: ((self.view.frame.width)/2) - 25)
        layout.minimumLineSpacing = -20
        layout.minimumInteritemSpacing = 1
        self.collectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else { fatalError() }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        if let requestID = cell.requestID {
            imageManager.cancelImageRequest(requestID)
        }
        cell.imageView.image = nil
        let element = photoAssets.filter { $0.index == selectedPhotos[indexPath.item] }.first!
        cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width*2, height: cell.imageView.frame.height*2), contentMode: .aspectFill, options: options) { (image, info) in
            cell.imageView.image = image
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        ud.set(selectedPhotos[indexPath.item], forKey: "photoID_value")
        performSegue(withIdentifier: "fPhotos-Photo", sender: nil)
    }
}
