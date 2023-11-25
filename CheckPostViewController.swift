//
//  CheckPostViewController.swift
//  PhotoCategorizer
//
//  Created by Sato Masayuki on 2021/10/26.
//

import UIKit
import Photos

class CheckPostViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let imageManager = PHImageManager()
    let im1 = PHImageManager()
    let im2 = PHImageManager()
    let im3 = PHImageManager()

    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBAction func postButton(_ sender: Any) {
    }
    @IBOutlet weak var albumCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var albumCollectionView: UICollectionView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var photoCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewheight: NSLayoutConstraint!
    @IBOutlet weak var viewOnScroll: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        albumCollectionView.delegate = self
        albumCollectionView.dataSource = self
        albumCollectionView.register(UINib(nibName: "AlbumCellViewController", bundle: nil), forCellWithReuseIdentifier: "AlbumCellViewController")
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.view.frame.width-60)/3, height: (self.view.frame.width)*2/7)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = -10
        albumCollectionView.collectionViewLayout = layout
        
        let pLayout = UICollectionViewFlowLayout()
        pLayout.itemSize = CGSize(width: (self.view.frame.width-60)/3, height: (self.view.frame.width)*2/7)
        pLayout.minimumInteritemSpacing = 1
        pLayout.minimumLineSpacing = -20
        photoCollectionView.collectionViewLayout = pLayout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == albumCollectionView {
            return selectedAlbumArray.count
        } else {
            return selectedPhotoArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        if collectionView == albumCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCellViewController", for: indexPath) as? AlbumCellViewController else { fatalError() }
            cell.imageView1Width.constant = cell.frame.width*2/3
            cell.imageView2Width.constant = cell.frame.width/3
            cell.imageView3Width.constant = cell.frame.width/3
            cell.imageView1Height.constant = cell.frame.height - 20
            cell.imageView2Height.constant = (cell.frame.height-20)/2
            cell.imageView3Height.constant = (cell.frame.height-20)/2
            if let req1 = cell.req1 {
                im1.cancelImageRequest(req1)
            }
            if let req2 = cell.req2 {
                im2.cancelImageRequest(req2)
            }
            if let req3 = cell.req3 {
                im3.cancelImageRequest(req3)
            }
            cell.imageView1.image = nil
            cell.imageView2.image = nil
            cell.imageView3.image = nil
            let element1 = photoAssets.filter { $0.index == selectedAlbumArray[indexPath.item].album.album[0].imageID }.first!
            cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width, height: cell.imageView1.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                cell.imageView1.image = image
            })
            if selectedAlbumArray[indexPath.item].album.album.count > 2 {
                let element2 = photoAssets.filter { $0.index == selectedAlbumArray[indexPath.item].album.album[1].imageID }.first!
                let element3 = photoAssets.filter { $0.index == selectedAlbumArray[indexPath.item].album.album[2].imageID }.first!
                cell.req2 = im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                    cell.imageView2.image = image
                })
                cell.req3 = im3.requestImage(for: element3.asset, targetSize: CGSize(width: cell.imageView3.frame.width, height: cell.imageView3.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                    cell.imageView3.image = image
                })
            } else if selectedAlbumArray[indexPath.item].album.album.count == 2 {
                let element2 = photoAssets.filter { $0.index == selectedAlbumArray[indexPath.item].album.album[1].imageID }.first!
                cell.req2 = im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                    cell.imageView2.image = image
                })
                cell.imageView3.backgroundColor = .darkGray
            } else {
                cell.imageView2.backgroundColor = .lightGray
                cell.imageView3.backgroundColor = .darkGray
            }
            cell.label.text = selectedAlbumArray[indexPath.item].album.name
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else { fatalError() }
            if let requestID = cell.requestID {
                imageManager.cancelImageRequest(requestID)
            }
            cell.imageView.image = nil
            let element = photoAssets.filter { $0.index == selectedPhotoArray[indexPath.item].photo.imageID }.first!
            cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width, height: cell.imageView.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                cell.imageView.image = image
            })
            return cell
        }
    }
}
