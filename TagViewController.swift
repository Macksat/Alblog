//
//  TagViewController.swift
//  TagViewController
//
//  Created by Sato Masayuki on 2021/09/04.
//

import UIKit
import RealmSwift
import Photos

class TagViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var tagArray = [String]()
    let ud = UserDefaults.standard
    let realm = try! Realm()
    var button = UIButton()
    var imageManager = PHImageManager()

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBAction func addButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        
        textField.delegate = self
        textField.layer.cornerRadius = 10
        textField.backgroundColor = .systemGray6
                
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.collectionView.collectionViewLayout = layout
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        longPressRecognizer.delegate = self
        longPressRecognizer.allowableMovement = 10
        longPressRecognizer.minimumPressDuration = 0.7
        self.collectionView.addGestureRecognizer(longPressRecognizer)
        
        saveTagArray()
       
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        let element = photoAssets.filter { $0.index == ud.integer(forKey: "photoID_value") }.first!
        imageManager.requestImage(for: element.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) in
            self.imageView.image = image
        }
        imageView.layer.cornerRadius = 15
        imageViewHeight.constant = (self.view.frame.width - 40) * 3 / 5
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.height - textField.frame.size.height - textField.layer.position.y < keyboardSize.height {
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
    
    @objc func tapFunc() {
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
    }
    
    func saveTagArray() {
        let result = realm.objects(Tag.self)
        for i in result {
            tagArray.append(i.tag)
        }
        
        let orderedSet = NSOrderedSet(array: tagArray)
        tagArray = orderedSet.array as! [String]
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: button)) {
            return false
        }
        return true
    }
    
    @objc func longPressAction(sender: UILongPressGestureRecognizer) {
        let point: CGPoint = sender.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        if let indexPath = indexPath {
            switch sender.state {
            case .began:
                button.frame = CGRect(x: point.x, y: point.y + self.collectionView.frame.origin.y, width: 80, height: 40)
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
        let photo = realm.objects(Photo.self).filter("imageID == \(ud.integer(forKey: "photoID_value"))")
        let result = realm.objects(Tag.self)
        for i in result {
            for p in photo {
                if i.tag == tagArray[number] {
                    if i.imageID == Int() || i.imageID == p.imageID {
                        try! realm.write {
                            realm.delete(i)
                        }
                    }
                }
            }
        }
        tagArray.removeAll()
        saveTagArray()
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
        collectionView.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
                            tagBool = true
                            let tag = Tag()
                            tag.tag = a
                            tag.imageID = i.imageID
                            try! realm.write {
                                i.tag.append(tag)
                            }
                        }
                    }
                    if tagBool == false {
                        let newTag = Tag()
                        newTag.tag = textField.text!
                        try! realm.write {
                            realm.add(newTag)
                        }
                        let tag = Tag()
                        tag.tag = textField.text!
                        tag.imageID = i.imageID
                        try! realm.write {
                            i.tag.append(tag)
                        }
                    }
                }
            }
        }
            
        textField.text = ""
        tagArray.removeAll()
        saveTagArray()
        collectionView.reloadData()
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as? CustomCell else {
            fatalError("Could not create custom cell.")
        }
        cell.layer.cornerRadius = 10
                    
        let id = ud.integer(forKey: "photoID_value")
        let photos = realm.objects(Photo.self).filter("imageID == \(id)")
        var bool = false
        for  i in photos {
            for a in i.tag {
                if tagArray[indexPath.item] == a.tag {
                    bool = true
                }
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
        let id = ud.integer(forKey: "photoID_value")
        let photos = realm.objects(Photo.self).filter("imageID == \(id)")
        var bool = false
        for i in photos {
            for t in i.tag {
                if tagArray[indexPath.item] == t.tag {
                    try! realm.write {
                        realm.delete(t)
                    }
                    bool = true
                }
            }
            
            if bool == true {
                cell.backgroundColor = .systemGray6
                cell.tagLabel.textColor = .label
            } else {
                let tag = Tag()
                tag.tag = tagArray[indexPath.item]
                tag.imageID = i.imageID
                try! realm.write {
                    i.tag.append(tag)
                }
                cell.backgroundColor = .systemRed
                cell.tagLabel.textColor = .white
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

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.representedElementCategory == .cell {
                if layoutAttribute.frame.origin.y >= maxY {
                    leftMargin = sectionInset.left
                }
                layoutAttribute.frame.origin.x = leftMargin
                leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
                maxY = max(layoutAttribute.frame.maxY, maxY)
            }
        }
        return attributes
    }
}
