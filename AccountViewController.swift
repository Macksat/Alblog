//
//  AccountViewController.swift
//  AccountViewController
//
//  Created by Sato Masayuki on 2021/09/25.
//

import UIKit

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate {
    
    var albumArray = [Album]()
    var photoArray = [Photo]()
    var accountArray = [(image: UIImage, name: String)]()
    var titleArray = ["Albums", "Photos"]

    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBAction func addButton(_ sender: Any) {
        performSegue(withIdentifier: "goPost", sender: nil)
    }
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var followerNumber: UILabel!
    @IBOutlet weak var followerLabel: UILabel!
    @IBOutlet weak var followsNumber: UILabel!
    @IBOutlet weak var followsLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBAction func editButton(_ sender: Any) {
        performSegue(withIdentifier: "goSetting", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomTableViewCell", bundle: nil), forCellReuseIdentifier: "CustomTableViewCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        textView.delegate = self
        textView.layer.cornerRadius = 15
        
        scrollView.delegate = self
        
        iconImage.layer.cornerRadius = iconImage.frame.size.width/2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectedAlbumArray.removeAll()
        selectedPhotoArray.removeAll()
        
        if imageView.image == nil {
            imageView.backgroundColor = .darkGray
        } else {
            imageView.backgroundColor = .clear
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        setLayout()
    }
    
    func setLayout() {
        tableViewHeight.constant = CGFloat.greatestFiniteMagnitude
        tableView.layoutIfNeeded()
        tableView.rowHeight = UITableView.automaticDimension
        tableViewHeight.constant = tableView.contentSize.height
        scrollViewHeight.constant = CGFloat.greatestFiniteMagnitude
        let height = imageView.frame.size.height + iconImage.frame.size.height + followerNumber.frame.size.height * 2 + textView.frame.size.height + tableViewHeight.constant + collectionView.frame.size.height
        scrollViewHeight.constant = height + 125 + (self.navigationController?.navigationBar.frame.size.height)! + (self.tabBarController?.tabBar.frame.size.height)!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? CustomTableViewCell else { fatalError() }
        cell.setCollectionDelegateDataSource(dataSourceDelegate: self, forRow: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as? CustomTableViewCell else { fatalError() }
        cell.moreButton.setTitle("See more", for: .normal)
        cell.moreButton.addTarget(self, action: #selector(moreButtonAction(sender:)), for: .touchUpInside)
        cell.moreButton.tag = indexPath.row
        cell.collectionView.tag = indexPath.row
        cell.setUpContents(string: titleArray[indexPath.row])
        return cell
    }
    
    @objc func moreButtonAction(sender: UIButton) {
        if sender.tag == 0 {
            
        } else {
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            return accountArray.count
        } else {
            if section == 0 {
                return albumArray.count
            } else {
                return photoArray.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            guard let image = cell.viewWithTag(1) as? UIImageView else { fatalError() }
            guard let label = cell.viewWithTag(2) as? UILabel else { fatalError() }
            image.image = accountArray[indexPath.item].image
            label.text = accountArray[indexPath.item].name
            return cell
        } else {
            if indexPath.section == 0 {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCellViewController", for: indexPath) as? AlbumCellViewController else { fatalError() }
                return cell
            } else {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else { fatalError() }
                return cell
            }
        }
    }
}
