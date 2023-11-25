//
//  SearchResultController.swift
//  PhotoCategorizer
//
//  Created by Sato Masayuki on 2021/08/14.
//

import UIKit

class SearchResultController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let ud = UserDefaults.standard
    var urlArray = [String]()
    let apiKey = "AIzaSyAnpE79AGkv98bYkaMdzSW0Z3p0GrMPc6s"
    let cx = "20471edf0111f889c"
    let url = "https://www.googleapis.com/customsearch/v1"
    let searchType = "image"

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.collectionView.backgroundColor = .systemGray6
        self.view.backgroundColor = .systemGray6
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.view.frame.width-60)/2, height: (self.view.frame.width-40)*4/10)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        collectionView.collectionViewLayout = layout
        
        configureRefreshControl()
    }
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)) -> SearchResultController {
        let controller = storyboard.instantiateViewController(withIdentifier: "SearchResultController") as! SearchResultController
        return controller
    }
    
    func configureRefreshControl() {
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
    }
    
    @objc func refreshAction() {
        let parameter = ["key": apiKey, "cx": cx, "searchType": searchType, "q": ud.string(forKey: "searchText_value")!]
        let requestURL = ViewController().createRequestURL(parameter: parameter)
        ViewController().request(requestURL: requestURL) { result in
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.collectionView.refreshControl?.endRefreshing()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return webImageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
            fatalError("could not create grid cell.")
        }
        
        if let url = URL(string: webImageArray[indexPath.item]) {
            let req = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: req, completionHandler: {data, response, error in
                if let data = data {
                    if let anImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.setUpContents(image: anImage, string: imageTitleArray[indexPath.item])
                        }
                    }
                }
            })
            task.resume()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        ud.set(webImageArray[indexPath.item], forKey: "webImage_value")
        ud.set(imageTitleArray[indexPath.item], forKey: "webTitle_value")
        ud.set(webURLArray[indexPath.item], forKey: "webURL_value")
        performSegue(withIdentifier: "goWebDetail", sender: nil)
    }
}
