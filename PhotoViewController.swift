//
//  PhotoViewController.swift
//  PhotoCategorizer
//
//  Created by Masayuki Sato on 2021/07/06.
//

import UIKit
import RealmSwift
import FloatingPanel
import CoreML
import Vision
import Photos

var objectArray = [VNClassificationObservation]()

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, FloatingPanelControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate {
    
    let ud = UserDefaults.standard
    var tagArray = [String]()
    let realm = try! Realm()
    var tableView = UITableView()
    var buttonBool = false
    var editButtonBool = false
    var modalView: FloatingPanelController!
    var searchText = String()
    var textArray = [String]()
    var imageManager = PHImageManager()
    var tv1 = UITextView()
    var deleteButton = UIButton()
    var titleButton = UIButton()
    var detailButtonBool = (Int(), false)
    var memoEditBool = false
    var memoCollectionView: UICollectionView!
    var preScrollViewOffset = CGFloat()
    
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBAction func favoriteButton(_ sender: Any) {
        let photo = realm.objects(Photo.self).filter("imageID == \(ud.integer(forKey: "photoID_value"))").first!
        if favoriteButton.image == UIImage(systemName: "heart") {
            try! realm.write {
                photo.favorite = true
            }
            favoriteButton.image = UIImage(systemName: "heart.fill")
            favoriteButton.tintColor = .systemRed
        } else {
            try! realm.write {
                photo.favorite = false
            }
            favoriteButton.image = UIImage(systemName: "heart")
            favoriteButton.tintColor = .systemBlue
        }
    }
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var memoViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var memoView: UIView!
    @IBOutlet weak var memoEditButton: UIButton!
    @IBAction func memoEditButton(_ sender: Any) {
        if memoEditButton.titleLabel?.text == "Edit" {
            memoEditButton.setTitle("Done", for: .normal)
            UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                self.cellAddButton.tintColor = .systemBlue
                self.cellAddButton.setImage(UIImage(systemName: "plus"), for: .normal)
                self.cellAddButton.backgroundColor = .systemGray4
                self.cellAddButton.layer.cornerRadius = 10
                self.cellAddButton.isEnabled = true
            }, completion: nil)
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations:  {
                self.modalView.move(to: .tip, animated: false)
            }, completion: nil)
            memoEditBool = true
        } else {
            memoTableView.endEditing(true)
            memoEditButton.setTitle("Edit", for: .normal)
            UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                self.cellAddButton.setImage(UIImage(), for: .normal)
                self.cellAddButton.backgroundColor = .clear
                self.cellAddButton.isEnabled = false
            }, completion: nil)
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations:  {
                self.modalView.move(to: .half, animated: false)
            }, completion: nil)
            memoEditBool = false
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    @IBOutlet weak var viewOnScroll: UIView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var memoTableView: UITableView!
    @IBOutlet weak var detailButton: UIBarButtonItem!
    @IBAction func detailButton(_ sender: Any) {
        if editButtonBool == false {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "popupCell")
            tableView.frame = CGRect(x: self.view.frame.width - 160, y: scrollView.contentOffset.y, width: 150, height: 44*2)
            tableView.backgroundColor = .systemGray6
            tableView.layer.cornerRadius = 10
            tableView.isScrollEnabled = false
            viewOnScroll.addSubview(tableView)
            editButtonBool = true
        } else {
            tableView.removeFromSuperview()
            editButtonBool = false
        }
    }
    @IBOutlet weak var cellAddButton: UIButton!
    @IBAction func cellAddButton(_ sender: Any) {
        if buttonBool == false {
            memoCollectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
            memoCollectionView.delegate = self
            memoCollectionView.dataSource = self
            let point: CGPoint = cellAddButton.convert(CGPoint.zero, to: viewOnScroll)
            if point.y < self.view.frame.height + scrollView.contentOffset.y - (self.navigationController?.navigationBar.frame.height)! - (self.tabBarController?.tabBar.frame.height)! - 200 {
                memoCollectionView.layer.position = CGPoint(x: self.view.frame.width/2, y: point.y + 100)
            } else {
                memoCollectionView.layer.position = CGPoint(x: self.view.frame.width/2, y: point.y - 80)
            }
            memoCollectionView.layer.cornerRadius = 10
            memoCollectionView.backgroundColor = .systemGray5
            scrollView.addSubview(memoCollectionView)
            buttonBool = true
        } else if buttonBool == true {
            memoCollectionView.removeFromSuperview()
            buttonBool = false
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        let tagLayout = LeftAlignedCollectionViewFlowLayout()
        tagLayout.scrollDirection = .vertical
        tagLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        tagLayout.minimumInteritemSpacing = 10
        tagLayout.minimumLineSpacing = 10
        tagLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = tagLayout
        
        memoTableView.delegate = self
        memoTableView.dataSource = self
        memoTableView.register(UINib(nibName: "MemoTableViewCell", bundle: nil), forCellReuseIdentifier: "MemoTableViewCell")
        memoTableView.register(UINib(nibName: "GridTableViewCell", bundle: nil), forCellReuseIdentifier: "GridTableViewCell")
        memoTableView.register(UINib(nibName: "LinkInTableViewCell", bundle: nil), forCellReuseIdentifier: "LinkInTableViewCell")
        memoTableView.register(UINib(nibName: "SheetTableViewCell", bundle: nil), forCellReuseIdentifier: "SheetTableViewCell")
        memoTableView.register(UINib(nibName: "ListTableViewCell", bundle: nil), forCellReuseIdentifier: "ListTableViewCell")
        memoTableView.register(UINib(nibName: "TitleTableViewCell", bundle: nil), forCellReuseIdentifier: "TitleTableViewCell")
        memoTableView.backgroundColor = .clear
        memoTableView.layer.cornerRadius = 15
        
        scrollView.delegate = self
        
        self.cellAddButton.setImage(UIImage(), for: .normal)
        cellAddButton.isEnabled = false
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        let element = photoAssets.filter { $0.index == ud.integer(forKey: "photoID_value") }.first!
        imageManager.requestImage(for: element.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) in
            self.imageView.image = image
        }
        imageView.layer.cornerRadius = 15
        imageViewHeight.constant = (self.view.frame.width - 40) * 3 / 4
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.view.frame.width/6, height: 100)
        layout.minimumInteritemSpacing = 1
        layout.scrollDirection = .horizontal
        memoCollectionView = UICollectionView(frame: CGRect(x: 10, y: 40, width: self.view.frame.width - 20, height: 120), collectionViewLayout: layout)
        
        memoView.layer.cornerRadius = 18
        
        let photo = realm.objects(Photo.self).filter("imageID == \(ud.integer(forKey: "photoID_value"))").first!
        if photo.favorite == true {
            favoriteButton.image = UIImage(systemName: "heart.fill")
            favoriteButton.tintColor = .systemRed
        } else {
            favoriteButton.image = UIImage(systemName: "heart")
            favoriteButton.tintColor = .systemBlue
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        getWebData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        objectArray.removeAll()
        tagArray.removeAll()
        linkArray.removeAll()
        let id = ud.integer(forKey: "photoID_value")
        let result = realm.objects(Photo.self).filter("imageID == \(id)")
        for i in result {
            if i.memos.count != 0 {
                for l in i.memos[0].link {
                    linkArray.append(l)
                }
            }
            for t in i.tag {
                tagArray.append(t.tag)
            }
        }
        
        let orderedSet = NSOrderedSet(array: tagArray)
        tagArray = orderedSet.array as! [String]
        
        collectionView.reloadData()
        tableViewKindSave()
        memoTableView.reloadData()
        changeLayoutOfMemo()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        changeLayoutOfMemo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func changeLayoutOfMemo() {
        self.tableViewHeight.constant = CGFloat.greatestFiniteMagnitude
        self.memoTableView.layoutIfNeeded()
        memoTableView.rowHeight = UITableView.automaticDimension
        self.tableViewHeight.constant = self.memoTableView.contentSize.height
        
        self.memoViewHeight.constant = CGFloat.greatestFiniteMagnitude
        self.memoView.layoutIfNeeded()
        self.memoViewHeight.constant = self.tableViewHeight.constant + 60
        
        self.scrollViewHeight.constant = CGFloat.greatestFiniteMagnitude
        self.scrollViewHeight.constant = self.imageView.frame.size.height + self.collectionView.frame.size.height + 113 + self.tableViewHeight.constant + 60
    }
    
    func tableViewKindSave() {
        let photo = realm.objects(Photo.self).filter("imageID == \(ud.integer(forKey: "photoID_value"))").first!
        tableViewKind.removeAll()
        for i in photo.memos {
            if i.memo != "" {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("memo", i)
                let element2 = ("blank", Memos())
                tableViewKind.append(element)
                tableViewKind.append(element2)
            }
            if i.link.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("link", i)
                tableViewKind.append(element)
                let element2 = ("blank", Memos())
                tableViewKind.append(element2)
            }
            if i.boolList.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                for _ in 1...i.boolList.count {
                    let element = ("list", i)
                    tableViewKind.append(element)
                }
                if memoEditBool == true {
                    let element = ("list", i)
                    tableViewKind.append(element)
                }
                let element2 = ("blank", Memos())
                tableViewKind.append(element2)
            }
            if i.sheet.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                for _ in 1...i.sheet.count {
                    let element = ("sheet", i)
                    tableViewKind.append(element)
                }
                if memoEditBool == true {
                    let element = ("sheet", i)
                    tableViewKind.append(element)
                }
                let element2 = ("blank", Memos())
                tableViewKind.append(element2)
            }
            if i.grid.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("grid", i)
                let element2 = ("blank", Memos())
                tableViewKind.append(element)
                tableViewKind.append(element2)
            }
        }
        if tableViewKind.count != 0 {
            if tableViewKind.last!.name == "blank" {
                tableViewKind.remove(at: tableViewKind.count - 1)
            }
        }
    }
    
    func getWebData() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        let element = photoAssets.filter { $0.index == ud.integer(forKey: "photoID_value") }.first!
        imageManager.requestImage(for: element.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
            self.detectImageObject(image: image!)
            
            for i in self.tagArray {
                self.textArray.append(i)
            }
            webImageArray.removeAll()
            webURLArray.removeAll()
            imageTitleArray.removeAll()
            self.modalView = FloatingPanelController()
            self.modalView.delegate = self
            self.modalView.layout = MyFloatingPanelLayout()
            let appearance = SurfaceAppearance()
            appearance.cornerRadius = 15
            self.modalView.surfaceView.appearance = appearance
            let src = ImageSearchViewController.fromStoryboard()
            let parameter = ["key": apiKey, "cx": cx, "searchType": searchType, "q": self.searchText]
            let requestURL = self.createRequestURL(parameter: parameter)
            self.request(requestURL: requestURL) { result in
                DispatchQueue.main.async {
                    self.modalView.set(contentViewController: src)
                    self.modalView.track(scrollView: src.resultCollectionView)
                    self.modalView.addPanel(toParent: self)
                }
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: memoCollectionView)) {
            return false
        } else if (touch.view!.isDescendant(of: tableView)) {
            return false
        } else if (touch.view!.isDescendant(of: titleButton)) {
            return false
        } else if (touch.view!.isDescendant(of: deleteButton)) {
            return false
        }
        return true
    }
    
    @IBAction func imageViewAction(_ sender: Any) {
        ud.set("photoVC", forKey: "segue_value")
        if buttonBool == true {
            tableView.removeFromSuperview()
            buttonBool = false
        }
        performSegue(withIdentifier: "photo-full", sender: nil)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        preScrollViewOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != memoCollectionView {
            if buttonBool == true {
                self.memoCollectionView.removeFromSuperview()
                buttonBool = false
            }
            if editButtonBool == true {
                UIView.transition(with: viewOnScroll, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                    self.tableView.removeFromSuperview()
                })
                editButtonBool = false
            }
            if detailButtonBool.1 == true {
                UIView.transition(with: viewOnScroll, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                    self.titleButton.removeFromSuperview()
                    self.deleteButton.removeFromSuperview()
                })
                detailButtonBool.1 = false
            }
        }
        
        if memoEditBool == false {
            if scrollView.contentOffset.y > preScrollViewOffset {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations:  {
                    self.modalView.move(to: .tip, animated: false)
                }, completion: nil)
            } else if scrollView.contentOffset.y < preScrollViewOffset {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations:  {
                    self.modalView.move(to: .half, animated: false)
                }, completion: nil)
            }
        }
    }
    
    @objc func tapFunc() {
        if buttonBool == true {
            memoCollectionView.removeFromSuperview()
            buttonBool = false
        }
        if editButtonBool == true {
            tableView.removeFromSuperview()
            editButtonBool = false
        }
        if detailButtonBool.1 == true {
            titleButton.removeFromSuperview()
            deleteButton.removeFromSuperview()
            detailButtonBool.1 = false
        }
        memoTableView.endEditing(true)
        if memoEditBool == false {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations:  {
                self.modalView.move(to: .half, animated: false)
            }, completion: nil)
        }
    }
    
    @objc func textViewDoneButton() {
        memoTableView.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let height = self.ud.double(forKey: "textViewPoint_index")
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if height + 163 + self.imageView.frame.size.height + self.collectionView.frame.size.height > self.scrollView.contentOffset.y + self.view.frame.height - keyboardSize.height - 44 {
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                        if self.view.frame.origin.y == 0 {
                            self.view.frame.origin.y -= keyboardSize.height
                        } else {
                            let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                            self.view.frame.origin.y -= suggestionHeight
                        }
                    }, completion: nil)
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == memoTableView {
            return tableViewKind.count
        } else if tableView == self.tableView {
            return 2
        } else {
            if tableView.tag == section {
                if tableViewKind[section].name == "link" {
                    return tableViewKind[section].memo.link.count*2 - 1
                }
            }
            return Int()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == memoTableView {
            return 1
        } else if tableView == self.tableView {
            return 1
        } else {
            return tableViewKind.count
        }
    }
   
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "blank" {
                return 10
            } else if tableViewKind[indexPath.row].name == "grid" {
                var num = Int()
                if memoEditBool == true {
                    num = (tableViewKind[indexPath.row].memo.grid.count + 1) % 2
                    if num == 0 {
                        return ((self.view.frame.width - 60)/2 - 10)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2
                    } else {
                        return ((self.view.frame.width - 60)/2 - 10)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 2)/2
                    }
                } else {
                    num = tableViewKind[indexPath.row].memo.grid.count % 2
                    if num == 0 {
                        return ((self.view.frame.width - 60)/2 - 10)*CGFloat(tableViewKind[indexPath.row].memo.grid.count)/2
                    } else {
                        return ((self.view.frame.width - 60)/2 - 10)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2
                    }
                }
            } else if tableViewKind[indexPath.row].name == "link" {
                if memoEditBool == true {
                    return CGFloat(70*tableViewKind[indexPath.row].memo.link.count) + 20
                } else {
                    return CGFloat(70*tableViewKind[indexPath.row].memo.link.count) - 10
                }
            } else {
                return tableView.rowHeight
            }
        } else if tableView == self.tableView {
            return 44
        } else {
            let num = (indexPath.row + 1) % 2
            if num != 0 {
                return 60
            } else {
                return 10
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "grid" {
                guard let cell = cell as? GridTableViewCell else {
                    return
                }
                cell.setCollectionDelegateDataSource(dataSourceDelegate: self, forRow: indexPath.row)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "memo" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "MemoTableViewCell", for: indexPath) as? MemoTableViewCell else {
                    fatalError()
                }
                cell.contentView.backgroundColor = .systemBackground
                cell.contentView.layer.cornerRadius = 15
                if tableViewKind[indexPath.row].memo.memo != "" {
                    cell.textView.text = tableViewKind[indexPath.row].memo.memo
                    let height = cell.textView.sizeThatFits(CGSize(width: cell.textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cell.textViewHeight.constant = height
                } else {
                    cell.textViewHeight.constant = 30
                }
                cell.textView.delegate = self
                cell.textView.tag = indexPath.row
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView.inputAccessoryView = toolbar
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.textView.isUserInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 5
                    cell.detailButton.isEnabled = false
                    cell.textView.isUserInteractionEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.detailButton.titleLabel?.text = ""
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "grid" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "GridTableViewCell", for: indexPath) as? GridTableViewCell else {
                    fatalError("Could not create cell.")
                }
                cell.contentView.backgroundColor = .systemBackground
                cell.contentView.layer.cornerRadius = 15
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.collectionView.isUserInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 5
                    cell.detailButton.isEnabled = false
                    cell.collectionView.isUserInteractionEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.collectionView.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "list" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as? ListTableViewCell else {
                    fatalError()
                }
                cell.contentView.backgroundColor = .systemBackground
                if indexPath.row > 0 && indexPath.row < tableViewKind.count - 1 {
                    if tableViewKind[indexPath.row - 1].name != "list" {
                        cell.contentView.layer.cornerRadius = 15
                        cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    } else if tableViewKind[indexPath.row + 1].name != "list" {
                        cell.contentView.layer.cornerRadius = 15
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    } else {
                        cell.contentView.layer.cornerRadius = 0
                    }
                    if tableViewKind[indexPath.row - 1].name != "list" && tableViewKind[indexPath.row + 1].name != "list" {
                        cell.contentView.layer.cornerRadius = 15
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
                    }
                }
                if indexPath.row == 0 {
                    cell.contentView.layer.cornerRadius = 15
                    cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row + 1].name != "list" {
                            cell.contentView.layer.cornerRadius = 15
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                if indexPath.row == tableViewKind.count - 1 {
                    cell.contentView.layer.cornerRadius = 15
                    cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row - 1].name != "list" {
                            cell.contentView.layer.cornerRadius = 15
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                cell.textView.delegate = self
                cell.textView.tag = indexPath.row
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView.inputAccessoryView = toolbar
                var id = Int()
                if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != tableViewKind[indexPath.row].memo.id {
                    if indexPath.row - 1 >= 0 {
                        var num = 1
                        while tableViewKind[indexPath.row - num].name == "list" {
                            num += 1
                        }
                        id = indexPath.row - num + 1
                    } else {
                        id = 0
                    }
                }
                if tableViewKind[indexPath.row].memo.boolList.count >= indexPath.row - id + 1 {
                    cell.textView.text = tableViewKind[indexPath.row].memo.boolList[indexPath.row - id].text
                    let height = cell.textView.sizeThatFits(CGSize(width: cell.textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cell.textViewHeight.constant = height
                    if tableViewKind[indexPath.row].memo.boolList[indexPath.row - id].bool == false {
                        cell.button.tintColor = .lightGray
                    } else {
                        cell.button.tintColor = .systemRed
                    }
                } else {
                    cell.textView.text = ""
                    cell.textViewHeight.constant = 30
                    cell.button.tintColor = .lightGray
                }
                cell.button.tag = indexPath.row
                cell.button.addTarget(self, action: #selector(listButtonAction(sender:)), for: .touchUpInside)
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.textView.isUserInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 0
                    cell.detailButton.isEnabled = false
                    cell.textView.isUserInteractionEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "sheet" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SheetTableViewCell", for: indexPath) as? SheetTableViewCell else {
                    fatalError()
                }
                cell.contentView.backgroundColor = .systemBackground
                if indexPath.row > 0 && indexPath.row < tableViewKind.count - 1 {
                    if tableViewKind[indexPath.row - 1].name != "sheet" {
                        cell.contentView.layer.cornerRadius = 15
                        cell.textView1.layer.cornerRadius = 15
                        cell.textView2.layer.cornerRadius = 15
                        cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                        cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner]
                        cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner]
                    } else if tableViewKind[indexPath.row + 1].name != "sheet" {
                        cell.contentView.layer.cornerRadius = 15
                        cell.textView1.layer.cornerRadius = 15
                        cell.textView2.layer.cornerRadius = 15
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        cell.textView1.layer.maskedCorners = [.layerMinXMaxYCorner]
                        cell.textView2.layer.maskedCorners = [.layerMaxXMaxYCorner]
                    } else {
                        cell.contentView.layer.cornerRadius = 0
                        cell.textView1.layer.cornerRadius = 0
                        cell.textView2.layer.cornerRadius = 0
                    }
                    if tableViewKind[indexPath.row - 1].name != "sheet" && tableViewKind[indexPath.row + 1].name != "sheet" {
                        cell.contentView.layer.cornerRadius = 15
                        cell.textView1.layer.cornerRadius = 15
                        cell.textView2.layer.cornerRadius = 15
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
                        cell.textView1.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
                        cell.textView2.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
                    }
                }
                if indexPath.row == 0 {
                    cell.contentView.layer.cornerRadius = 15
                    cell.textView1.layer.cornerRadius = 15
                    cell.textView2.layer.cornerRadius = 15
                    cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row + 1].name != "sheet" {
                            cell.contentView.layer.cornerRadius = 15
                            cell.textView1.layer.cornerRadius = 15
                            cell.textView2.layer.cornerRadius = 15
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                            cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                            cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                if indexPath.row == tableViewKind.count - 1 {
                    cell.contentView.layer.cornerRadius = 15
                    cell.textView1.layer.cornerRadius = 15
                    cell.textView2.layer.cornerRadius = 15
                    cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    cell.textView1.layer.maskedCorners = [.layerMinXMaxYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMaxYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row - 1].name != "sheet" {
                            cell.contentView.layer.cornerRadius = 15
                            cell.textView1.layer.cornerRadius = 15
                            cell.textView2.layer.cornerRadius = 15
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                            cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                            cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                cell.textView1.delegate = self
                cell.textView2.delegate = self
                cell.textView1.tag = indexPath.row
                cell.textView2.tag = indexPath.row
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView1.inputAccessoryView = toolbar
                cell.textView2.inputAccessoryView = toolbar
                var id = Int()
                if tableViewKind[0].name != "sheet" || tableViewKind[0].memo.id != tableViewKind[indexPath.row].memo.id {
                    if indexPath.row - 1 >= 0 {
                        var num = 1
                        while tableViewKind[indexPath.row - num].name == "sheet" {
                            num += 1
                        }
                        id = indexPath.row - num + 1
                    } else {
                        id = 0
                    }
                }
                if tableViewKind[indexPath.row].memo.sheet.count >= indexPath.row - id + 1 {
                    cell.textView1.text = tableViewKind[indexPath.row].memo.sheet[indexPath.row - id].text1
                    cell.textView2.text = tableViewKind[indexPath.row].memo.sheet[indexPath.row - id].text2
                    let height1 = cell.textView1.sizeThatFits(CGSize(width: cell.textView1.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    let height2 = cell.textView2.sizeThatFits(CGSize(width: cell.textView2.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    if height1 > height2 {
                        cell.textView1Height.constant = height1
                        cell.textView2Height.constant = height1
                    } else {
                        cell.textView1Height.constant = height2
                        cell.textView2Height.constant = height2
                    }
                } else {
                    cell.textView1.text = ""
                    cell.textView2.text = ""
                    cell.textView1Height.constant = 35
                    cell.textView2Height.constant = 35
                }
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.textView1.isUserInteractionEnabled = true
                    cell.textView2.isUserInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 0
                    cell.detailButton.isEnabled = false
                    cell.textView1.isUserInteractionEnabled = false
                    cell.textView2.isUserInteractionEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "blank" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "blankCell", for: indexPath)
                cell.backgroundColor = .clear
                cell.isUserInteractionEnabled = false
                return cell
            } else if tableViewKind[indexPath.row].name == "link" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "LinkInTableViewCell", for: indexPath) as? LinkInTableViewCell else {
                    fatalError("Could not create cell.")
                }
                cell.addButton.tag = indexPath.row
                cell.tableView.tag = indexPath.row
                cell.tableView.delegate = self
                cell.tableView.dataSource = self
                cell.backgroundColor = .systemGray6
                if memoEditBool == true {
                    cell.addButton.setTitle("Add Link", for: .normal)
                    cell.addButton.isEnabled = true
                    cell.addButtonHeight.constant = 30
                    cell.tableView.allowsSelection = false
                } else {
                    cell.addButton.setTitle("", for: .normal)
                    cell.addButton.isEnabled = false
                    cell.addButtonHeight.constant = 0
                    cell.tableView.allowsSelection = true
                }
                cell.addButton.addTarget(self, action: #selector(addButtonAction(sender:)), for: .touchUpInside)
                cell.tableView.reloadData()
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCell", for: indexPath) as? TitleTableViewCell else {
                    fatalError("Could not create cell.")
                }
                cell.textField.delegate = self
                cell.textField.tag = indexPath.row
                cell.textField.text = tableViewKind[indexPath.row].memo.title
                if memoEditBool == true {
                    cell.isUserInteractionEnabled = true
                    cell.textField.isEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.textField.isEnabled = false
                }
                return cell
            }
        } else if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "popupCell", for: indexPath)
            if indexPath.row == 0 {
                cell.textLabel?.text = "Edit tags"
            } else {
                cell.textLabel?.text = "Delete photo"
                cell.textLabel?.textColor = .systemRed
            }
            cell.backgroundColor = .systemGray6
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            return cell
        } else {
            let num = (indexPath.row + 1) % 2
            if num != 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath) as? LinkTableViewCell else {
                    fatalError()
                }
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                cell.textField.tag = indexPath.row
                cell.textField.delegate = self
                cell.contentView.layer.cornerRadius = 15
                cell.backgroundColor = .systemGray6
                cell.contentView.backgroundColor = .systemBackground
                let imageData = tableViewKind[indexPath.section].memo.link[indexPath.row / 2].image as Data
                cell.setUpContents(image: UIImage(data: imageData)!, string: tableViewKind[indexPath.section].memo.link[indexPath.row / 2].title)
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButton.tintColor = .systemBlue
                    cell.detailButton.isEnabled = true
                    cell.detailButtonWidth.constant = 30
                    cell.textField.isEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 5
                    cell.detailButton.isEnabled = false
                    cell.textField.isEnabled = false
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "blankCell", for: indexPath)
                cell.backgroundColor = .systemGray6
                cell.isUserInteractionEnabled = false
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == memoTableView {
            
        } else if tableView == self.tableView {
            if indexPath.row == 0 {
                performSegue(withIdentifier: "goTag", sender: nil)
                
                tableView.removeFromSuperview()
                buttonBool = false
            } else {
                let alertController = UIAlertController(title: "Do you want to delete this photo?", message: "", preferredStyle: .alert)
                let yesAction = UIAlertAction(title: "Delete", style: .destructive) { UIAlertAction in
                    let album = self.realm.objects(Album.self).filter("id == \(self.ud.integer(forKey: "view-albumContents"))")
                    let photo = self.realm.objects(Photo.self).filter("imageID == \(self.ud.integer(forKey: "photoID_value"))")
                    for p in album[0].album {
                        if p == photo[0] {
                            try! self.realm.write {
                                album[0].album.remove(at: album[0].album.index(of: p)!)
                            }
                        }
                    }
                    self.navigationController?.popViewController(animated: true)
                }
                let noAction = UIAlertAction(title: "No", style: .cancel) { UIAlertAction in
                }
                alertController.addAction(yesAction)
                alertController.addAction(noAction)
                present(alertController, animated: true, completion: nil)
                
                tableView.removeFromSuperview()
                buttonBool = false
            }
        } else {
            ud.set(tableViewKind[indexPath.section].memo.link[indexPath.row/2].url, forKey: "webURL_value")
            performSegue(withIdentifier: "photoLink-web", sender: nil)
            tableView.deselectRow(at: indexPath, animated: false)
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        let point = textView.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        if tableViewKind[indexPath.row].name == "grid" {
            guard let cell = memoTableView.cellForRow(at: indexPath) as? GridTableViewCell else {
                fatalError()
            }
            if let start = textView.selectedTextRange?.start {
                let cursorFrame = textView.caretRect(for: start)
                let gPoint = textView.convert(CGPoint.zero, to: cell.collectionView)
                ud.set(Double(cursorFrame.origin.y + gPoint.y + textView.frame.size.height), forKey: "textViewPoint_index")
            }
        } else {
            if let start = textView.selectedTextRange?.start {
                let cursorFrame = textView.caretRect(for: start)
                let point = textView.convert(CGPoint.zero, to: memoTableView)
                ud.set(Double(cursorFrame.origin.y + point.y + textView.frame.size.height), forKey: "textViewPoint_index")
            }
        }
        if tableViewKind[indexPath.row].name == "sheet" {
            guard let cell = memoTableView.cellForRow(at: indexPath) as? SheetTableViewCell else {
                fatalError()
            }
            tv1 = cell.textView1
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let point = textView.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        if let cell = memoTableView.cellForRow(at: indexPath) as? MemoTableViewCell {
            let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            cell.textViewHeight.isActive = true
            let originalHeight = cell.frame.size.height
            var frame = textView.frame
            frame.size.height = textView.contentSize.height
            textView.frame = frame
            var cellFrame = cell.frame
            cellFrame.size.height = height + 10
            cell.frame = cellFrame
            if originalHeight < cell.frame.size.height {
                if cell.frame.origin.y + cell.frame.size.height + imageView.frame.size.height + collectionView.frame.size.height + 163 >= scrollViewHeight.constant - 30 {
                    tableViewHeight.constant += 16.666666666666664
                    memoViewHeight.constant += 16.666666666666664
                    scrollViewHeight.constant += 16.666666666666664
                    scrollView.contentOffset.y += 16.666666666666664
                }
            } else if originalHeight > cell.frame.size.height {
                if tableViewHeight.constant > memoTableView.contentSize.height {
                    tableViewHeight.constant -= 16.666666666666664
                    memoViewHeight.constant -= 16.666666666666664
                    scrollViewHeight.constant -= 16.666666666666664
                }
            }
        } else if let cell = memoTableView.cellForRow(at: indexPath) as? ListTableViewCell {
            let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            cell.textViewHeight.isActive = true
            let originalHeight = cell.frame.size.height
            var frame = textView.frame
            frame.size.height = textView.contentSize.height
            textView.frame = frame
            var cellFrame = cell.frame
            cellFrame.size.height = height + 10
            cell.frame = cellFrame
            if originalHeight < cell.frame.size.height {
                if cell.frame.origin.y + cell.frame.size.height + imageView.frame.size.height + collectionView.frame.size.height + 163 >= scrollViewHeight.constant - 30 {
                    tableViewHeight.constant += 16.666666666666664
                    memoViewHeight.constant += 16.666666666666664
                    scrollViewHeight.constant += 16.666666666666664
                    scrollView.contentOffset.y += 16.666666666666664
                }
            } else if originalHeight > cell.frame.size.height {
                if tableViewHeight.constant > memoTableView.contentSize.height {
                    tableViewHeight.constant -= 16.666666666666664
                    memoViewHeight.constant -= 16.666666666666664
                    scrollViewHeight.constant -= 16.666666666666664
                }
            }
        } else if let cell = memoTableView.cellForRow(at: indexPath) as? SheetTableViewCell {
            let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            cell.textView1Height.isActive = true
            cell.textView2Height.isActive = true
            let originalHeight = cell.frame.size.height
            var frame = textView.frame
            frame.size.height = textView.contentSize.height
            textView.frame = frame
            var cellFrame = cell.frame
            if textView == cell.textView1 {
                if height > cell.textView2Height.constant {
                    cellFrame.size.height = height + 10
                } else {
                    cellFrame.size.height = cell.textView2Height.constant
                }
            } else {
                if height > cell.textView1Height.constant {
                    cellFrame.size.height = height + 10
                } else {
                    cellFrame.size.height = cell.textView1Height.constant
                }
            }
            cell.frame = cellFrame
            if originalHeight < cell.frame.size.height {
                if cell.frame.origin.y + cell.frame.size.height + imageView.frame.size.height + collectionView.frame.size.height + 163 >= scrollViewHeight.constant - 30 {
                    tableViewHeight.constant += 16.666666666666664
                    memoViewHeight.constant += 16.666666666666664
                    scrollViewHeight.constant += 16.666666666666664
                    scrollView.contentOffset.y += 16.666666666666664
                }
            } else if originalHeight > cell.frame.size.height {
                if tableViewHeight.constant > memoTableView.contentSize.height {
                    tableViewHeight.constant -= 16.666666666666664
                    memoViewHeight.constant -= 16.666666666666664
                    scrollViewHeight.constant -= 16.666666666666664
                }
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let tag = textView.tag
        let point = textView.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        var id = 0
        if tableViewKind[indexPath.row].name == "memo" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
            if textView.text != "" {
                try! realm.write {
                    memos.memo = textView.text
                }
            }
        } else if tableViewKind[indexPath.row].name == "grid" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
            if textView.text != "" {
                if tag == memos.grid.count {
                    let grid = Grid()
                    grid.text = textView.text
                    grid.gridID = tag
                    try! realm.write {
                        memos.grid.append(grid)
                    }
                } else {
                    try! realm.write {
                        memos.grid[tag].text = textView.text
                    }
                }
            }
        } else if tableViewKind[indexPath.row].name == "list" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
            if textView.text != "" {
                if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != memos.id {
                    if tag - 1 >= 0 {
                        var num = 1
                        while tableViewKind[tag - num].name == "list" {
                            num += 1
                        }
                        id = tag - num + 1
                    } else {
                        id = 0
                    }
                }
                if memos.boolList.count == tag - id {
                    let list = BoolList()
                    list.text = textView.text
                    list.listID = tag - id
                    try! realm.write {
                        memos.boolList.append(list)
                    }
                } else {
                    try! realm.write {
                        memos.boolList[tag - id].text = textView.text
                    }
                }
            }
        } else if tableViewKind[indexPath.row].name == "sheet" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
            if textView.text != "" {
                if tableViewKind[0].name != "sheet" || tableViewKind[0].memo.id != memos.id {
                    if tag - 1 >= 0 {
                        var num = 1
                        while tableViewKind[tag - num].name == "sheet" {
                            num += 1
                        }
                        id = tag - num + 1
                    } else {
                        id = 0
                    }
                }
                if memos.sheet.count == tag - id {
                    let sheet = Sheet()
                    if textView == tv1 {
                        sheet.text1 = textView.text
                        sheet.text2 = ""
                    } else {
                        sheet.text1 = ""
                        sheet.text2 = textView.text
                    }
                    sheet.sheetID = tag - id
                    try! realm.write {
                        memos.sheet.append(sheet)
                    }
                } else {
                    try! realm.write {
                        if textView == tv1 {
                            memos.sheet[tag - id].text1 = textView.text
                        } else {
                            memos.sheet[tag - id].text2 = textView.text
                        }
                    }
                }
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let start = textField.selectedTextRange?.start {
            let cursorFrame = textField.caretRect(for: start)
            let point = textField.convert(CGPoint.zero, to: memoTableView)
            ud.set(Double(cursorFrame.origin.y + point.y), forKey: "textViewPoint_index")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let tag = textField.tag
        let point = textField.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)")
        if textField.text != "" {
            if tableViewKind[indexPath.row].name == "title" {
                try! realm.write {
                    memos[0].title = textField.text!
                }
            } else if tableViewKind[indexPath.row].name == "grid" {
                let gridMemos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
                if tag == gridMemos.grid.count {
                    let grid = Grid()
                    grid.title = textField.text!
                    grid.gridID = tag
                    try! realm.write {
                        gridMemos.grid.append(grid)
                    }
                } else {
                    try! realm.write {
                        gridMemos.grid[tag].title = textField.text!
                    }
                }
            } else if tableViewKind[indexPath.row].name == "link" {
                let linkMemos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
                try! realm.write {
                    linkMemos.link[tag/2].title = textField.text!
                }
            }
        } else {
            if tableViewKind[tag].name == "title" {
                try! realm.write {
                    memos[0].title == ""
                }
            }
            if tableViewKind[indexPath.row].name == "link" {
                textField.text = tableViewKind[indexPath.row].memo.link[tag/2].title
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    
    @objc func detailButtonAction(sender: UIButton) {
        let tag = sender.tag
        
        let point = sender.convert(CGPoint.zero, to: viewOnScroll)
        titleButton.frame = CGRect(x: self.view.frame.width - 140, y: point.y - 22.5, width: 80, height: 45)
        deleteButton.frame = CGRect(x: self.view.frame.width - 140, y: point.y + 22.5, width: 80, height: 45)
        titleButton.layer.cornerRadius = 10
        titleButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        deleteButton.layer.cornerRadius = 10
        deleteButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        titleButton.backgroundColor = .systemGray5
        deleteButton.backgroundColor = .systemGray5
        titleButton.setTitle("Title", for: .normal)
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        titleButton.addTarget(self, action: #selector(titleButtonAction(sender:)), for: .touchUpInside)
        let memoPoint = sender.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: memoPoint)!
        if tableViewKind[indexPath.row].name == "link" {
            titleButton.tag = indexPath.row
            deleteButton.tag = indexPath.row
            ud.set(tag/2, forKey: "linkTag_index")
        } else {
            titleButton.tag = tag
            deleteButton.tag = tag
        }
        deleteButton.addTarget(self, action: #selector(deleteButtonAction(sender:)), for: .touchUpInside)
        if detailButtonBool.1 == false {
            viewOnScroll.addSubview(titleButton)
            viewOnScroll.addSubview(deleteButton)
            detailButtonBool = (tag, true)
        } else {
            if detailButtonBool.0 == tag {
                titleButton.removeFromSuperview()
                deleteButton.removeFromSuperview()
                detailButtonBool = (tag, false)
            } else {
                titleButton.removeFromSuperview()
                deleteButton.removeFromSuperview()
                viewOnScroll.addSubview(titleButton)
                viewOnScroll.addSubview(deleteButton)
                detailButtonBool = (tag, true)
            }
        }
    }
    
    @objc func titleButtonAction(sender: UIButton) {
        var num = 0
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        if memos.title == "" {
            if tableViewKind[0].memo.id != memos.id {
                while tableViewKind[tag - num].name != "blank" {
                    num += 1
                }
                if tableViewKind[tag - num + 1].name == "title" {
                    tableViewKind.remove(at: tag - num + 1)
                }
                tableViewKind.insert(("title", memos), at: tag - num + 1)
            } else {
                tableViewKind.insert(("title", memos), at: 0)
            }
        } else {
            while tableViewKind[tag - num].name != "title" {
                num += 1
            }
            try! realm.write {
                memos.title = ""
            }
            tableViewKind.remove(at: tag - num)
        }
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
        titleButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        detailButtonBool.1 = false
    }
    
    @objc func deleteButtonAction(sender: UIButton) {
        let tag = sender.tag
        var id = 0
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        if tableViewKind[tag].name == "sheet" {
            if tableViewKind[0].name != "sheet" || tableViewKind[0].memo.id != memos.id {
                if tag - 1 >= 0 {
                    var num = 1
                    while tableViewKind[tag - num].name == "sheet" {
                        num += 1
                    }
                    id = tag - num + 1
                } else {
                    id = 0
                }
            }
            if tag - id < memos.sheet.count {
                if memos.sheet.count == 1 {
                    try! realm.write {
                        realm.delete(memos)
                    }
                } else {
                    try! realm.write {
                        memos.sheet.remove(at: tag - id)
                    }
                }
            }
        } else if tableViewKind[tag].name == "list" {
            if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != memos.id {
                if tag - 1 >= 0 {
                    var num = 1
                    while tableViewKind[tag - num].name == "list" {
                        num += 1
                    }
                    id = tag - num + 1
                } else {
                    id = 0
                }
            }
            if tag - id < memos.boolList.count {
                if memos.sheet.count == 1 {
                    try! realm.write {
                        realm.delete(memos)
                    }
                } else {
                    try! realm.write {
                        memos.boolList.remove(at: tag - id)
                    }
                }
            }
        } else if tableViewKind[tag].name == "link" {
            let linkTag = ud.integer(forKey: "linkTag_index")
            try! realm.write {
                memos.link.remove(at: linkTag)
            }
        } else {
            try! realm.write {
                realm.delete(memos)
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
        titleButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        detailButtonBool.1 = false
    }
    
    @objc func listButtonAction(sender: UIButton) {
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        var id = Int()
        if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != memos.id {
            if tag - 1 >= 0 {
                var num = 1
                while tableViewKind[tag - num].name == "list" {
                    num += 1
                }
                id = tag - num + 1
            } else {
                id = 0
            }
        }
        if memos.boolList.count != tag - id {
            if tableViewKind[tag].memo.boolList[tag - id].bool == false {
                sender.tintColor = .red
                try! realm.write {
                    memos.boolList[tag - id].bool = true
                }
            } else {
                sender.tintColor = .lightGray
                try! realm.write {
                    memos.boolList[tag - id].bool = false
                }
            }
        } else {
            let list = BoolList()
            list.bool = true
            list.listID = tag - id
            try! realm.write {
                memos.boolList.append(list)
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    
    @objc func addButtonAction(sender: UIButton) {
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        if tableViewKind[tag].name == "link" {
            ud.set(memos.id, forKey: "memosLink_id")
            performSegue(withIdentifier: "photo-searchURL", sender: nil)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == memoCollectionView {
            return 1
        } else if collectionView == self.collectionView {
            return 1
        } else {
            return tableViewKind.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == memoCollectionView {
            return 5
        } else if collectionView == self.collectionView {
            return tagArray.count
        } else {
            if collectionView.tag == section {
                if tableViewKind[section].name == "grid" {
                    if memoEditBool == true {
                        return tableViewKind[section].memo.grid.count + 1
                    } else {
                        return tableViewKind[section].memo.grid.count
                    }
                }
            }
            return Int()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == memoCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
                fatalError("Could not create cell.")
            }
            if indexPath.item == 0 {
                cell.setUpContents(image: UIImage(named: "blank")!, string: "Memo")
            } else if indexPath.item == 1 {
                cell.setUpContents(image: UIImage(named: "blank")!, string: "Grid")
            } else if indexPath.item == 2 {
                cell.setUpContents(image: UIImage(named: "blank")!, string: "List")
            } else if indexPath.item == 3 {
                cell.setUpContents(image: UIImage(named: "blank")!, string: "Sheet")
            } else {
                cell.setUpContents(image: UIImage(named: "blank")!, string: "Link")
            }
            cell.label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            
            return cell
        } else if collectionView == self.collectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as? CustomCell else {
                fatalError("Could not create cell.")
            }
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            }
            cell.tagLabel.text = tagArray[indexPath.item]
            cell.tagLabel.textColor = .white
            cell.backgroundColor = .systemRed
            cell.layer.cornerRadius = 10
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextCollectionViewCell", for: indexPath) as? TextCollectionViewCell else {
                fatalError()
            }
            cell.textView.tag = indexPath.item
            cell.title.tag = indexPath.item
            cell.deleteButton.tag = indexPath.item
            cell.textView.delegate = self
            cell.title.delegate = self
            let toolbar = UIToolbar()
            toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
            let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
            toolbar.setItems([doneButtonItem], animated: true)
            cell.textView.inputAccessoryView = toolbar
            cell.deleteButton.addTarget(self, action: #selector(contentDeleteButtonAction(sender:)), for: .touchUpInside)
            if memoEditBool == true {
                cell.deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                cell.deleteButton.tintColor = .systemRed
                cell.deleteButton.backgroundColor = .systemGray6
                cell.deleteButton.layer.cornerRadius = 10
                cell.deleteButton.layer.maskedCorners = [.layerMaxXMinYCorner]
                cell.title.layer.maskedCorners = [.layerMinXMinYCorner]
                cell.deleteButtonWidth.constant = 30
            } else {
                cell.deleteButton.setImage(UIImage(), for: .normal)
                cell.deleteButton.backgroundColor = .clear
                cell.title.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                cell.deleteButtonWidth.constant = 0
            }
            if indexPath.item <= tableViewKind[indexPath.section].memo.grid.count - 1 {
                cell.title.text = tableViewKind[indexPath.section].memo.grid[indexPath.item].title
                cell.textView.text = tableViewKind[indexPath.section].memo.grid[indexPath.item].text
            } else {
                cell.title.text = ""
                cell.textView.text = ""
            }
            
            return cell
        }
    }
    
    @objc func contentDeleteButtonAction(sender: UIButton) {
        let tag = sender.tag
        let point = sender.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
        if tableViewKind[indexPath.row].name == "grid" {
            if tag < memos.grid.count {
                try! realm.write {
                    memos.grid.remove(at: tag)
                }
            }
        } else if tableViewKind[indexPath.row].name == "link" {
            if tag < memos.link.count {
                try! realm.write {
                    memos.link.remove(at: tag)
                }
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    
    func refreshMemosData() {
        let photo = realm.objects(Photo.self).filter("imageID == \(ud.integer(forKey: "photoID_value"))").first!
        for i in photo.memos {
            if i.memo == "" && i.grid.count == 0 && i.boolList.count == 0 && i.sheet.count == 0 && i.link.count == 0 {
                try! realm.write {
                    realm.delete(i)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == memoCollectionView {
            refreshMemosData()
            let photo = realm.objects(Photo.self).filter("imageID == \(ud.integer(forKey: "photoID_value"))").first!
            tableViewKindSave()
            let memos = Memos()
            memos.id = Memos.newID()
            if photo.memos.count != 0 {
                memos.number = photo.memos.last!.number + 1
            } else {
                memos.number = 1
            }
            try! realm.write {
                photo.memos.append(memos)
            }
            let blankElement = ("blank", Memos())
            tableViewKind.append(blankElement)
            if indexPath.item == 0 {
                let element = ("memo", memos)
                tableViewKind.append(element)
            } else if indexPath.item == 1 {
                let element = ("grid", memos)
                tableViewKind.append(element)
            } else if indexPath.item == 2 {
                let element = ("list", memos)
                tableViewKind.append(element)
            } else if indexPath.item == 3 {
                let element = ("sheet", memos)
                tableViewKind.append(element)
            } else {
                let element = ("link", memos)
                tableViewKind.append(element)
            }
            if tableViewKind.first!.name == "blank" {
                tableViewKind.remove(at: 0)
            }
            memoTableView.reloadData()
            memoCollectionView.removeFromSuperview()
            buttonBool = false
            self.viewWillLayoutSubviews()
            changeLayoutOfMemo()
            scrollView.contentOffset.y = scrollViewHeight.constant - self.view.frame.height + (self.tabBarController?.tabBar.frame.height)! + (self.navigationController?.navigationBar.frame.height)! + 20
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            let label = UILabel(frame: CGRect.zero)
            label.font = UIFont.systemFont(ofSize: 17)
            label.text = tagArray[indexPath.item]
            label.sizeToFit()
            let size = label.frame.size
            return CGSize(width: size.width + 25, height: 30)
        } else if collectionView == memoCollectionView {
            return CGSize(width: 80, height: 100)
        } else {
            if memoEditBool == true {
                return CGSize(width: (self.view.frame.width - 60)/2 - 22.5, height: (self.view.frame.width - 60)/2 - 20)
            } else {
                return CGSize(width: (self.view.frame.width - 60)/2 - 10, height: (self.view.frame.width - 60)/2 - 20)
            }
        }
    }
    
    func classifyObject(image: UIImage) {
        //let configuration = MLModelConfiguration()
        //guard let ciImage = CIImage(image: image), let model = try? VNCoreMLModel(for: YOLOv3(configuration: configuration).model) else {
            //fatalError("Could not create model.")
        //}
        //DispatchQueue.main.async {
            //let request = VNCoreMLRequest(model: model) { (request, error) in
                //guard let results = request.results as? [VNClassificationObservation] else {
                    //return
                //}
                //for i in results {
                    //objectArray.append(i)
                //}
            //}
            
            //let handler = VNImageRequestHandler(ciImage: ciImage)
            //do {
               // try handler.perform([request])
            //} catch {
               // print(error)
            //}
        //}
    }
    
    // 画像からオブジェクトを検出・結果を出力
    func detectImageObject(image: UIImage) {
        //let configuration = MLModelConfiguration()
        //guard let ciImage = CIImage(image: image), let model = try? VNCoreMLModel(for: PhotoCategorizerTestML1_1(configuration: configuration).model) else {
            //fatalError("Could not create model.")
        //}
        // Core MLモデルを使用して画像を処理する画像解析リクエスト
        //let request = VNCoreMLRequest(model: model) { (request, error) in
            // 解析結果を分類情報として保存
            //guard let results = request.results as? [VNClassificationObservation] else {
                //return
            //}

            // 画像内の一番割合が大きいオブジェクトを出力する
            //if let firstResult = results.first {
                //let objectArray = firstResult.identifier.components(separatedBy: ",")
                //if objectArray.count == 1 {
                    // classification name
                    //self.searchText = firstResult.identifier
                    
                //} else {
                    // classification name
                    //self.searchText = objectArray.first!
                    
                //}
            //}
        //}
        
        // 画像解析をリクエスト
        //let handler = VNImageRequestHandler(ciImage: ciImage)

        // リクエストを実行
        //do {
            //try handler.perform([request])
        //}
        //catch {
            //print(error)
        //}
    }
    
    //　パラメータのURLエンコード処理
    func encodeParameter(key: String, value: String) -> String? {
        guard let escapedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return nil
        }
        
        return "\(key)=\(escapedValue)"
    }
    
    // creating URL
    func createRequestURL(parameter: [String: String]) -> String {
        var parameterString = ""
        for key in parameter.keys {
            // 値の取り出し
            guard let value = parameter[key] else {
                continue
            }
            // すでにパラメータが設定されていた場合
            if parameterString.lengthOfBytes(using: String.Encoding.utf8) > 0 {
                parameterString += "&"
            }
            // 値をエンコードする
            guard let encodeValue = encodeParameter(key: key, value: value) else {
                continue
            }
            
            parameterString += encodeValue
        }
        
        let requestURL = googleURL + "?" + parameterString
        return requestURL
    }
    
    func parseData(items: [Any], resultHandler: @escaping (([String]?) -> Void)) {
        for i in items {
            // レスポンスデータから画像情報を取得する
            guard let item = i as? [String: Any], let imageURL = item["link"] as? String, let title = item["title"] as? String, let image = item["image"] as? [String: Any], let url = image["contextLink"] as? String else {
                resultHandler(nil)
                return
            }
            
            webImageArray.append(imageURL)
            imageTitleArray.append(title)
            webURLArray.append(url)
        }
        
        
        resultHandler(webImageArray)
    }
    
    // conducting request
    func request(requestURL: String, resultHandler: @escaping (([String]?) -> Void)) {
        guard let url = URL(string: requestURL) else {
            resultHandler(nil)
            return
        }
        
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            //print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue) ?? "")
            // checking error
            guard error == nil else {
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel)
                alert.addAction(okAction)
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                resultHandler(nil)
                return
            }
            // JSONで返却されたデータをパースして格納する
            guard let data = data else {
                resultHandler(nil)
                return
            }
            // transforming to JSON
            guard let jsonData = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] else {
                resultHandler(nil)
                return
            }
            
            // analyzing data
            guard let resultSet = jsonData["items"] as? [Any] else {
                resultHandler(nil)
                return
            }
            
            self.parseData(items: resultSet, resultHandler: resultHandler)
        }
        // 配信開始
        task.resume()
    }
}

class CustomCell: UICollectionViewCell {
    
    @IBOutlet weak var tagLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .half
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .bottom, referenceGuide: .safeArea),
        ]
    }
}
