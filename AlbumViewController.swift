//
//  AlbumViewController.swift
//  PhotoCategorizer
//
//  Created by Masayuki Sato on 2021/07/06.
//

import UIKit
import RealmSwift
import Photos

class AlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let realm = try! Realm()
    let ud = UserDefaults.standard
    var albums = [Album]()
    var im1 = PHImageManager()
    var im2 = PHImageManager()
    var im3 = PHImageManager()
    
    @IBOutlet weak var albumCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = ud.string(forKey: "albumNavigationTitle")
        
        albumCollectionView.delegate = self
        albumCollectionView.dataSource = self
        
        albumCollectionView.register(UINib(nibName: "AlbumCellViewController", bundle: nil), forCellWithReuseIdentifier: "AlbumCellViewController")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ((self.view.frame.width)/2) - 25, height: ((self.view.frame.width)/2) - 25)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = -10
        albumCollectionView.collectionViewLayout = layout
        
        let idArray = ud.array(forKey: "view-albumID") as! [Int]
        for i in idArray {
            let item = realm.objects(Album.self).filter("id == \(i)")
            for a in item {
                albums.append(a)
            }
        }
        let orderedSet = NSOrderedSet(array: albums)
        albums = orderedSet.array as! [Album]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCellViewController", for: indexPath) as? AlbumCellViewController else {
            fatalError("Could not create cell.")
        }
        cell.imageView1Width.constant = cell.frame.width*2/3
        cell.imageView2Width.constant = cell.frame.width/3
        cell.imageView3Width.constant = cell.frame.width/3
        cell.imageView1Height.constant = cell.frame.height - 20
        cell.imageView2Height.constant = (cell.frame.height-20)/2
        cell.imageView3Height.constant = (cell.frame.height-20)/2
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
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
        let element1 = photoAssets.filter { $0.index == albums[indexPath.item].album[0].imageID }.first!
        if albums[indexPath.item].album.count > 2 {
            let element2 = photoAssets.filter { $0.index == albums[indexPath.item].album[1].imageID }.first!
            let element3 = photoAssets.filter { $0.index == albums[indexPath.item].album[2].imageID }.first!
            cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width*2, height: cell.imageView1.frame.height*2), contentMode: .aspectFill, options: options) { (image1, info) in
                cell.req2 = self.im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options) { (image2, info) in
                    cell.req3 = self.im3.requestImage(for: element3.asset, targetSize: CGSize(width: cell.imageView3.frame.width, height: cell.imageView3.frame.height), contentMode: .aspectFill, options: options) { (image3, info) in
                        cell.imageView1.image = image1
                        cell.imageView2.image = image2
                        cell.imageView3.image = image3
                        cell.label.text = self.albums[indexPath.item].name
                    }
                }
            }
        } else if albums[indexPath.item].album.count == 2 {
            let element2 = photoAssets.filter { $0.index == albums[indexPath.item].album[1].imageID }.first!
            cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width*2, height: cell.imageView1.frame.height*2), contentMode: .aspectFill, options: options) { (image1, info) in
                cell.req2 = self.im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options) { (image2, info) in
                    cell.imageView1.image = image1
                    cell.imageView2.image = image2
                    cell.imageView3.backgroundColor = .darkGray
                    cell.label.text = self.albums[indexPath.item].name
                }
            }
        } else {
            cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width*2, height: cell.imageView1.frame.height*2), contentMode: .aspectFill, options: options) { (image1, info) in
                cell.imageView1.image = image1
                cell.imageView2.backgroundColor = .lightGray
                cell.imageView3.backgroundColor = .darkGray
                cell.label.text = self.albums[indexPath.item].name
            }
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = albums[indexPath.item].id
        ud.set(id, forKey: "view-albumContents")
        performSegue(withIdentifier: "album-photos", sender: nil)
    }
}
