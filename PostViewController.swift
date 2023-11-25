//
//  PostViewController.swift
//  PhotoCategorizer
//
//  Created by Sato Masayuki on 2021/10/26.
//

import UIKit
import RealmSwift
import Photos

var selectedAlbumArray = [(index: Int, album: Album)]()
var selectedPhotoArray = [(index: Int, photo: Photo)]()

class PostViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var albumArray = [Album]()
    var photoArray = [Photo]()
    var segmentStr = ""
    let realm = try! Realm()
    let imageManager = PHImageManager()
    let im1 = PHImageManager()
    let im2 = PHImageManager()
    let im3 = PHImageManager()

    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBAction func nextButton(_ sender: Any) {
        performSegue(withIdentifier: "goCheckPost", sender: nil)
    }
    @IBOutlet weak var segment: UISegmentedControl!
    @IBAction func segment(_ sender: Any) {
        switch segment.selectedSegmentIndex {
        case 0:
            segmentStr = "album"
        case 1:
            segmentStr = "Photo"
        default:
            break
        }
        collectionView.reloadData()
    }
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        collectionView.register(UINib(nibName: "AlbumCellViewController", bundle: nil), forCellWithReuseIdentifier: "AlbumCellViewController")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.view.frame.width-60)/3, height: (self.view.frame.width)*2/7)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = -10
        collectionView.collectionViewLayout = layout
        
        segmentStr = "album"
        
        saveArray()
    }
    
    func saveArray() {
        let photos = realm.objects(Photo.self)
        let albums = realm.objects(Album.self)
        for i in photos {
            photoArray.append(i)
        }
        for i in albums {
            if i.name != "" {
                albumArray.append(i)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if segmentStr == "album" {
            return albumArray.count
        } else {
            return photoArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        if segmentStr == "album" {
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
            let element1 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[0].imageID}.first!
            cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width, height: cell.imageView1.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                cell.imageView1.image = image
            })
            if albumArray[indexPath.item].album.count > 2 {
                let element2 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[1].imageID}.first!
                let element3 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[2].imageID}.first!
                cell.req2 = im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                    cell.imageView2.image = image
                })
                cell.req3 = im3.requestImage(for: element3.asset, targetSize: CGSize(width: cell.imageView3.frame.width, height: cell.imageView3.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                    cell.imageView3.image = image
                })
            } else if albumArray[indexPath.item].album.count == 2 {
                let element2 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[1].imageID}.first!
                cell.req2 = im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                    cell.imageView2.image = image
                })
                cell.imageView3.backgroundColor = .darkGray
            } else {
                cell.imageView2.backgroundColor = .lightGray
                cell.imageView3.backgroundColor = .darkGray
            }
            cell.label.text = albumArray[indexPath.item].name
            
            var bool = false
            for i in selectedAlbumArray {
                if i.index == indexPath.item {
                    bool = true
                }
            }
            cell.contentView.layer.cornerRadius = 10
            if bool == true {
                cell.contentView.layer.borderWidth = 3
                cell.contentView.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                cell.contentView.layer.borderWidth = 0
            }
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else { fatalError() }
            if let requestID = cell.requestID {
                imageManager.cancelImageRequest(requestID)
            }
            cell.imageView.image = nil
            let element = photoAssets.filter { $0.index == photoArray[indexPath.item].imageID }.first!
            cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width, height: cell.imageView.frame.height), contentMode: .aspectFill, options: options, resultHandler: { image, info in
                cell.imageView.image = image
            })
            
            var bool = false
            for i in selectedPhotoArray {
                if i.index == indexPath.item {
                    bool = true
                }
            }
            if bool == true {
                cell.imageView.layer.borderWidth = 3
                cell.imageView.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                cell.imageView.layer.borderWidth = 0
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if segmentStr == "album" {
            guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumCellViewController else { fatalError() }
            var bool = false
            for i in selectedAlbumArray {
                if indexPath.item == i.index {
                    bool = true
                }
            }
            if bool == false {
                cell.contentView.layer.cornerRadius = 10
                cell.contentView.layer.borderColor = UIColor.systemBlue.cgColor
                cell.contentView.layer.borderWidth = 3
                selectedAlbumArray.append((indexPath.item, albumArray[indexPath.item]))
            } else {
                cell.contentView.layer.borderWidth = 0
                for (index, i) in selectedAlbumArray.enumerated() {
                    if i.index == indexPath.item {
                        selectedAlbumArray.remove(at: index)
                    }
                }
            }
        } else {
            guard let cell = collectionView.cellForItem(at: indexPath) as? GridCellViewController else { fatalError() }
            var bool = false
            for i in selectedPhotoArray {
                if indexPath.item == i.index {
                    bool = true
                }
            }
            if bool == false {
                cell.imageView.layer.borderWidth = 3
                cell.imageView.layer.borderColor = UIColor.systemBlue.cgColor
                selectedPhotoArray.append((indexPath.item, photoArray[indexPath.item]))
            } else {
                cell.imageView.layer.borderWidth = 0
                for (index, i) in selectedPhotoArray.enumerated() {
                    if i.index == indexPath.item {
                        selectedPhotoArray.remove(at: index)
                    }
                }
            }
        }
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}
