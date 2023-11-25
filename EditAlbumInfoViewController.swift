//
//  EditAlbumInfoViewController.swift
//  EditAlbumInfoViewController
//
//  Created by Sato Masayuki on 2021/09/10.
//

import UIKit
import RealmSwift
import Photos

class EditAlbumInfoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    let ud = UserDefaults.standard
    let realm = try! Realm()
    var tagArray = [String]()
    var selectedTags = [String]()
    var button = UIButton()
    var albumName = String()
    var im1 = PHImageManager()
    var im2 = PHImageManager()
    var im3 = PHImageManager()

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneButton(_ sender: Any) {
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        
        try! realm.write {
            realm.delete(album.tag)
            album.name = albumName
        }
        for i in selectedTags {
            let tag = Tag()
            tag.tag = i
            tag.albumID = album.id
            try! realm.write {
                album.tag.append(tag)
            }
        }
        selectedTags.removeAll()
        self.navigationController?.popViewController(animated: true)
    }
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var tagTextField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        nameTextField.delegate = self
        tagTextField.delegate = self
        
        nameTextField.backgroundColor = .systemGray6
        nameTextField.layer.cornerRadius = 10
        tagTextField.backgroundColor = .systemGray6
        tagTextField.layer.cornerRadius = 10
        
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.collectionView.collectionViewLayout = layout
        
        saveTagArray()
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        albumName = album.name
        nameTextField.text = album.name
        for i in album.tag {
            selectedTags.append(i.tag)
        }
        let tagOrderedSet = NSOrderedSet(array: tagArray)
        tagArray = tagOrderedSet.array as! [String]
        let selectedOrderedSet = NSOrderedSet(array: selectedTags)
        selectedTags = selectedOrderedSet.array as! [String]
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        let element1 = photoAssets.filter { $0.index == album.album[0].imageID }.first!
        if album.album.count > 2 {
            let element2 = photoAssets.filter { $0.index == album.album[1].imageID }.first!
            let element3 = photoAssets.filter { $0.index == album.album[2].imageID }.first!
            im1.requestImage(for: element1.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image1, info) in
                self.im2.requestImage(for: element2.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image2, info) in
                    self.im3.requestImage(for: element3.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image3, info) in
                        self.imageView1.image = image1
                        self.imageView2.image = image2
                        self.imageView3.image = image3
                    }
                }
            }
        } else if album.album.count == 2 {
            let element2 = photoAssets.filter { $0.index == album.album[1].imageID }.first!
            im1.requestImage(for: element1.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image1, info) in
                self.im2.requestImage(for: element2.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image2, info) in
                    self.imageView1.image = image1
                    self.imageView2.image = image2
                }
            }
            imageView3.backgroundColor = .darkGray
        } else {
            im1.requestImage(for: element1.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image1, info) in
                self.imageView1.image = image1
            }
            imageView2.backgroundColor = .lightGray
            imageView3.backgroundColor = .darkGray
        }
        
        imageView1.layer.cornerRadius = 15
        imageView2.layer.cornerRadius = 15
        imageView3.layer.cornerRadius = 15
        imageView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        imageView2.layer.maskedCorners = [.layerMaxXMinYCorner]
        imageView3.layer.maskedCorners = [.layerMaxXMaxYCorner]
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        longPressRecognizer.delegate = self
        longPressRecognizer.allowableMovement = 10
        longPressRecognizer.minimumPressDuration = 0.7
        self.collectionView.addGestureRecognizer(longPressRecognizer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if scrollView.contentOffset.y + self.view.frame.height - nameTextField.frame.size.height - nameTextField.layer.position.y < keyboardSize.height {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                } else {
                    let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                    self.view.frame.origin.y -= suggestionHeight
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
            if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func saveTagArray() {
        let result = realm.objects(Tag.self)
        for i in result {
            tagArray.append(i.tag)
        }
        
        let orderedSet = NSOrderedSet(array: tagArray)
        tagArray = orderedSet.array as! [String]
    }
    
    @objc func tapFunc() {
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
        if tagTextField.isEditing == true {
            tagTextField.endEditing(true)
        } else if nameTextField.isEditing == true {
            nameTextField.endEditing(true)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: button)) {
            return false
        }
        return true
    }
    
    @objc func longPressAction(sender: UILongPressGestureRecognizer) {
        let scrollPoint: CGPoint = sender.location(in: scrollView)
        let point: CGPoint = sender.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        if let indexPath = indexPath {
            switch sender.state {
            case .began:
                button.frame = CGRect(x: scrollPoint.x, y: scrollPoint.y + 70, width: 80, height: 40)
                button.setTitle("Delete", for: .normal)
                button.setTitleColor(.systemRed, for: .normal)
                button.backgroundColor = .systemGray6
                button.layer.cornerRadius = 10
                button.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
                ud.set(indexPath.item, forKey: "tagIndexPath_value")
                UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                    self.view.addSubview(self.button)
                }, completion: nil)
            default:
                break
            }
        }
    }
    
    @objc func deleteButtonAction() {
        let number = ud.integer(forKey: "tagIndexPath_value")
        tagArray.remove(at: number)
        
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
        collectionView.reloadData()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        doneButton.isEnabled = false
        imageView1.isUserInteractionEnabled = false
        imageView2.isUserInteractionEnabled = false
        imageView3.isUserInteractionEnabled = false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        doneButton.isEnabled = false
        imageView1.isUserInteractionEnabled = false
        imageView2.isUserInteractionEnabled = false
        imageView3.isUserInteractionEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        doneButton.isEnabled = true
        imageView1.isUserInteractionEnabled = true
        imageView2.isUserInteractionEnabled = true
        imageView3.isUserInteractionEnabled = true
        if textField == nameTextField {
            let albums = realm.objects(Album.self)
            albumName = nameTextField.text!
            for i in albums {
                if i.name == textField.text {
                    doneButton.isEnabled = false
                }
            }
            if albumName == "" {
                doneButton.isEnabled = false
            } else {
                doneButton.isEnabled = true
            }
        } else {
            var boolA = false
            var boolB = false
            let id = ud.integer(forKey: "photoID_value")
            let photo = realm.objects(Photo.self).filter("imageID == \(id)")
            if textField.text != "" {
                for t in tagArray {
                    if textField.text == t {
                        boolA = true
                    }
                }
                
                for i in photo {
                    for t in i.tag {
                        if t.tag == textField.text {
                            boolB = true
                        }
                    }
                    
                    if boolA == false || boolA == true, boolB == false {
                        var tagBool = false
                        for a in tagArray {
                            if a == textField.text {
                                selectedTags.append(a)
                                tagBool = true
                            }
                        }
                        if tagBool == false {
                            selectedTags.append(textField.text!)
                            tagArray.append(textField.text!)
                        }
                    }
                }
            }
                
            textField.text = ""
            collectionView.reloadData()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CustomCell else {
            fatalError("Could not create cell.")
        }
        cell.layer.cornerRadius = 10
        var bool = false
        for i in selectedTags {
            if i == tagArray[indexPath.item] {
                bool = true
            }
        }
        
        if bool == true {
            cell.backgroundColor = .systemRed
            cell.tagLabel.textColor = .white
        } else {
            cell.backgroundColor = .systemGray6
            cell.tagLabel.textColor = .label
        }
        
        cell.tagLabel.text = tagArray[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath)! as? CustomCell else {
            fatalError("Could not define cell.")
        }
        var bool = false
        for i in selectedTags {
            if i == tagArray[indexPath.item] {
                bool = true
            }
        }
        if bool == false {
            cell.backgroundColor = .systemRed
            cell.tagLabel.textColor = .white
            selectedTags.append(tagArray[indexPath.item])
        } else {
            cell.backgroundColor = .systemGray6
            cell.tagLabel.textColor = .label
            for (index, i) in selectedTags.enumerated() {
                if i == tagArray[indexPath.item] {
                    selectedTags.remove(at: index)
                }
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 17)
        label.text = tagArray[indexPath.item]
        label.sizeToFit()
        let size = label.frame.size
        return CGSize(width: size.width + 25, height: 30)
    }
}
