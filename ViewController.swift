//
//  ViewController.swift
//  Alblog
//
//  Created by Sato Masayuki on 2021/10/31.
//

import UIKit
import RealmSwift
import WebKit
import FloatingPanel
import Photos
import Vision
import CoreML

var webImageArray = [String]()
var imageTitleArray = [String]()
var webURLArray = [String]()
let apiKey = "AIzaSyAnpE79AGkv98bYkaMdzSW0Z3p0GrMPc6s"
let cx = "20471edf0111f889c"
let googleURL = "https://www.googleapis.com/customsearch/v1"
let searchType = "image"
var photoAssets = [(asset: PHAsset, index: Int)]()
var launchBool = false

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, WKNavigationDelegate, UISearchBarDelegate, FloatingPanelControllerDelegate, UIGestureRecognizerDelegate {
    
    var album: Results<Album>!
    var photos: Results<Photo>!
    var dictionary = [(str: String, albums: [Album])]()
    var imageArray = [Data]()
    let realm = try! Realm()
    let ud = UserDefaults.standard
    var modalView: FloatingPanelController!
    var predictArray = [String]()
    var predictTableView = UITableView()
    var fetch = PHFetchResult<PHAsset>()
    var indicator = UIActivityIndicatorView()
    var imageManager = PHImageManager()
    var im1 = PHImageManager()
    var im2 = PHImageManager()
    var im3 = PHImageManager()
    var modalBool = false
    var categoryButton = UIButton()
    var detailBool = false
    public var reqID: PHImageRequestID?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBAction func createButton(_ sender: Any) {
        performSegue(withIdentifier: "goCreateAlbum", sender: nil)
    }
    @IBOutlet weak var detailButton: UIBarButtonItem!
    @IBAction func detailButton(_ sender: Any) {
        if detailBool == false {
            categoryButton.setTitle("Add Category", for: .normal)
            categoryButton.layer.cornerRadius = 10
            categoryButton.backgroundColor = .systemGray5
            categoryButton.setTitleColor(.label, for: .normal)
            categoryButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            categoryButton.frame = CGRect(x: self.view.frame.width - 140, y: (self.navigationController?.navigationBar.frame.origin.y)! + (self.navigationController?.navigationBar.frame.size.height)!, width: 120, height: 44)
            categoryButton.addTarget(self, action: #selector(categoryFunc), for: .touchUpInside)
            self.view.addSubview(categoryButton)
            detailBool = true
        } else {
            categoryButton.removeFromSuperview()
            detailBool = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CustomTableViewCell", bundle: nil), forCellReuseIdentifier: "CustomTableViewCell")
        
        searchBar.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        indicator.center = self.view.center
        indicator.style = .large
        indicator.color = .gray
        self.view.addSubview(indicator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectedPhotos.removeAll()
        selectedTags.removeAll()
        let bool = ud.bool(forKey: "firstBool")
        if bool != true {
            libraryRequestAuthorization()
            ud.set(true, forKey: "firstBool")
        } else {
            if launchBool == false {
                indicator.startAnimating()
                getAllPhotosInfo()
                launchBool = true
            } else {
                if modalBool == false {
                    saveFunc()
                } else {
                    indicator.startAnimating()
                    getAllPhotosInfo()
                }
            }
        }
    }
    
    func saveFunc() {
        dictionary.removeAll()
        let results = realm.objects(Album.self)
        var albums = [Album]()
        var photos = [Album]()
        var favAlbums = [Album]()
        var favPhotos = [Album]()
        for i in results {
            if i.name == "" {
                photos.append(i)
                let album = Album()
                for p in i.album {
                    if p.favorite == true {
                        album.album.append(p)
                    }
                }
                if album.album.count != 0 {
                    favPhotos.append(album)
                }
            } else {
                albums.append(i)
                if i.favorite == true {
                    favAlbums.append(i)
                }
            }
        }
        if favAlbums.count != 0 {
            let elementFA = ("Favorite Albums", favAlbums)
            dictionary.append(elementFA)
        }
        if favPhotos.count != 0 {
            let elementFP = ("Favorite Photos", favPhotos)
            dictionary.append(elementFP)
        }
        if albums.count != 0 {
            let elementA = ("Albums", albums)
            dictionary.append(elementA)
        }
        if photos.count != 0 {
            let elementP = ("Photos", photos)
            dictionary.append(elementP)
        }
                
        let category = realm.objects(Category.self)
        for i in category {
            var array = [Album]()
            for a in results {
                for t in a.tag {
                    if i.title == t.tag {
                        array.append(a)
                    }
                }
            }
            if array.count != 0 {
                let orderedSet = NSOrderedSet(array: array)
                array = orderedSet.array as! [Album]
                let newElement = (i.title, array)
                dictionary.append(newElement)
            }
        }
        let dicOrderedSet = NSOrderedSet(array: dictionary)
        dictionary = dicOrderedSet.array as! [(String, [Album])]
        
        tableView.reloadData()
    }
    
    @objc func categoryFunc() {
        performSegue(withIdentifier: "goAddCategory", sender: nil)
        categoryButton.removeFromSuperview()
        detailBool = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchBar.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func tapFunc() {
        if predictArray.count != 0 {
            predictTableView.removeFromSuperview()
        }
        if detailBool == true {
            categoryButton.removeFromSuperview()
            detailBool = false
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: predictTableView)) {
            return false
        } else if(touch.view!.isDescendant(of: categoryButton)) {
            return false
        }
        return true
    }
    
    // カメラロールへのアクセス許可
    fileprivate func libraryRequestAuthorization() {
        PHPhotoLibrary.requestAuthorization({ [weak self] status in
            guard let wself = self else {
                return
            }
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    wself.indicator.startAnimating()
                    wself.getAllPhotosInfo()
                }
            case .denied:
                wself.showDeniedAlert()
            case .notDetermined:
                print("NotDetermined")
            case .restricted:
                print("Restricted")
            case .limited:
                print("Limited")
            @unknown default:
                print("Error")
            }
        })
    }

    // カメラロールから全て取得する
    fileprivate func getAllPhotosInfo() {
        photoAssets.removeAll()
        DispatchQueue.global().async {
            let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: nil)
            assets.enumerateObjects({ [weak self] (asset, index, stop) -> Void in
                guard let pwself = self else {
                    return
                }
                autoreleasepool {
                    let element = (asset, index)
                    photoAssets.append(element)
                    if photoAssets.count == assets.count {
                        DispatchQueue.main.async {
                            let albums = pwself.realm.objects(Album.self)
                            if albums.count == 0 {
                                pwself.photoSave()
                                pwself.albumSave()
                                //pwself.detectImageObject()
                            } else {
                                let photos = pwself.realm.objects(Album.self).filter("id == \(1)").first!
                                if photoAssets.count > photos.album.count {
                                    pwself.newPhotoSave()
                                }
                            }
                            if pwself.modalBool == false {
                                pwself.saveFunc()
                            }
                            pwself.indicator.stopAnimating()
                        }
                    }
                }
            })
        }
    }
    
    func newPhotoSave() {
        let photos = realm.objects(Album.self).filter("id == \(1)").first!
        for i in photoAssets {
            autoreleasepool {
                var bool = false
                if photos.album.filter("imageID == \(i.index)").count == 0 {
                    bool = true
                }
                if bool == true {
                    let photo = Photo()
                    photo.imageID = i.index
                    try! realm.write {
                        photos.album.append(photo)
                    }
                }
            }
        }
    }
    
    // カメラロールへのアクセスが拒否されている場合のアラート
    fileprivate func showDeniedAlert() {
        let alert: UIAlertController = UIAlertController(title: "Error",
            message: "Rejected accessing to Photo Library. Please change the setting.",
            preferredStyle: .alert)
        let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel,
            handler: nil)
        let ok: UIAlertAction = UIAlertAction(title: "Go Setting", style: .default,
            handler: { [weak self] (action) -> Void in
                guard let wself = self else { return }
            wself.transitionToSettingsApplition()
        })
        alert.addAction(cancel)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func transitionToSettingsApplition() {
        let url = URL(string: UIApplication.openSettingsURLString)
        if let url = url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        dictionary.removeAll()
        if searchBar.text != "" {
            let result = realm.objects(Album.self)
            var albumResults = [Album]()
            var photoArray = [Photo]()
            var photoResults = [Album]()
            for i in result {
                for a in i.tag {
                    if a.tag.uppercased().contains(searchBar.text!.uppercased()) == true {
                        albumResults.append(i)
                    }
                }
                if i.name.uppercased().contains(searchBar.text!.uppercased()) == true {
                    albumResults.append(i)
                }
                for a in i.album {
                    for t in a.tag {
                        if t.tag.uppercased().contains(searchBar.text!.uppercased()) == true {
                            if i.name == "" {
                                photoArray.append(a)
                            } else {
                                albumResults.append(i)
                            }
                        }
                    }
                }
            }
            let albumOrderedSet = NSOrderedSet(array: albumResults)
            albumResults = albumOrderedSet.array as! [Album]
            if photoArray.count != 0 {
                let photoAlbum = Album()
                for i in photoArray {
                    photoAlbum.album.append(i)
                }
                photoResults.append(photoAlbum)
            }
            let albumStr = "Albums"
            let albumElement = (albumStr, albumResults)
            let photoStr = "Photos"
            let photoElement = (photoStr, photoResults)
            dictionary.append(albumElement)
            dictionary.append(photoElement)
        } else {
            saveFunc()
        }
        
        predictArray.removeAll()
        if predictArray.count != 0 {
            predictTableView.removeFromSuperview()
        }
        let tags = realm.objects(Tag.self)
        for i in tags {
            if i.tag.uppercased().contains(searchBar.text!.uppercased()) == true {
                predictArray.append(i.tag)
            }
        }
        let orderedSet = NSOrderedSet(array: predictArray)
        predictArray = orderedSet.array as! [String]
        
        predictTableView.frame = CGRect(x: 8, y: Int(self.searchBar.layer.position.y + self.searchBar.frame.height/2 - 15), width: Int(self.searchBar.frame.width) - 80, height: 45 * predictArray.count)
        predictTableView.register(UITableViewCell.self, forCellReuseIdentifier: "predictCell")
        predictTableView.delegate = self
        predictTableView.dataSource = self
        predictTableView.backgroundColor = .systemGray6
        predictTableView.layer.cornerRadius = 15
        predictTableView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        predictTableView.isScrollEnabled = false
        predictTableView.separatorStyle = .none
        self.view.addSubview(predictTableView)
        predictTableView.reloadData()
        
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        
        dictionary.removeAll()
        saveFunc()
        if modalBool == true {
            modalView.removePanelFromParent(animated: true)
            modalBool = false
        }
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if searchBar.text != "" {
            ud.set(searchBar.text, forKey: "searchBarText_value")
            dictionary.removeAll()
            let result = realm.objects(Album.self)
            var albums = [Album]()
            var photoArray = [Photo]()
            var photos = [Album]()
            for i in result {
                for a in i.album {
                    for t in a.tag {
                        if t.tag.uppercased() == searchBar.text?.uppercased() {
                            if i.name == "" {
                                photoArray.append(a)
                            } else {
                                albums.append(i)
                            }
                        }
                    }
                }
                if i.name.uppercased() == searchBar.text?.uppercased() {
                    albums.append(i)
                }
            }
            let photoOrderedSet = NSOrderedSet(array: photoArray)
            photoArray = photoOrderedSet.array as! [Photo]
            if photoArray.count != 0 {
                let photoAlbum = Album()
                for i in photoArray {
                    photoAlbum.album.append(i)
                }
                photos.append(photoAlbum)
            }
            let albumOrderedSet = NSOrderedSet(array: albums)
            albums = albumOrderedSet.array as! [Album]
            let albumStr = "Albums"
            let albumElement = (albumStr, albums)
            let photoStr = "Photos"
            let photoElement = (photoStr, photos)
            dictionary.append(albumElement)
            dictionary.append(photoElement)
            
            tableView.reloadData()
            
            ud.set(searchBar.text, forKey: "searchText_value")
            if webImageArray.count != 0 {
                webImageArray.removeAll()
                webURLArray.removeAll()
                imageTitleArray.removeAll()
            }
            
            if modalBool == true {
                modalView.removePanelFromParent(animated: true)
            }
            
            searchBar.setShowsCancelButton(false, animated: true)
            
            if let searchText = searchBar.text {
                self.modalView = FloatingPanelController()
                self.modalView.delegate = self
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 15
                self.modalView.surfaceView.appearance = appearance
                let src = SearchResultController.fromStoryboard()
               
                let parameter = ["key": apiKey, "cx": cx, "searchType": searchType, "q": searchText]
                let requestURL = createRequestURL(parameter: parameter)
                
                request(requestURL: requestURL) { result in
                    DispatchQueue.main.async {
                        self.modalView.set(contentViewController: src)
                        self.modalView.track(scrollView: src.collectionView)
                        self.modalView.addPanel(toParent: self)
                        self.modalBool = true
                    }
                }
            } else {
                searchBarCancelButtonClicked(searchBar)
                dictionary.removeAll()
                self.viewDidLoad()
            }
        }
        if self.predictArray.count != 0 {
            self.predictTableView.removeFromSuperview()
            self.predictArray.removeAll()
        }
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
    
    func photoSave() {
        for i in photoAssets {
            let photo = Photo()
            photo.imageID = i.index
            try! realm.write {
                realm.add(photo)
            }
        }
    }
    
    func albumSave() {
        let results = realm.objects(Photo.self)
        let albums = Album()
        for i in results {
            albums.album.append(i)
        }
        albums.album.sort { a, b in
            return a.imageID < b.imageID
        }
        albums.id = Album.newID()
        albums.name = ""
        try! realm.write {
            realm.add(albums)
        }
    }
    
    // 画像からオブジェクトを検出・結果を出力
    func detectImageObject() {
        //let configuration = MLModelConfiguration()
        //let photos = realm.objects(Photo.self)
        //let options = PHImageRequestOptions()
        //options.isNetworkAccessAllowed = true
        //for i in photos {
            //autoreleasepool {
                //let element = photoAssets.filter { $0.index == i.imageID}.first!
                //if reqID != nil {
                    //imageManager.cancelImageRequest(reqID!)
                //}
                //reqID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: options) { (image, info) in
                    //guard let ciImage = CIImage(image: image!), let model = try? VNCoreMLModel(for: MobileNetV2Int8LUT(configuration: configuration).model) else {
                        //fatalError("Could not create model.")
                    //}
                    // Core MLモデルを使用して画像を処理する画像解析リクエスト
                    //let request = VNCoreMLRequest(model: model) { (request, error) in
                        // 解析結果を分類情報として保存
                        //guard let results = request.results as? [VNClassificationObservation] else {
                           // return
                        //}
                        // 画像内の一番割合が大きいオブジェクトを出力する
                        //if let firstResult = results.first {
                            //let objectArray = firstResult.identifier.components(separatedBy: ",")
                            //let tag = Tag()
                            //tag.imageID = i.imageID
                            //if objectArray.count == 1 {
                                //tag.tag = firstResult.identifier
                                //try! self.realm.write {
                                    //i.tag.append(tag)
                                //}
                            //} else {
                                //tag.tag = objectArray.first!
                                //try! self.realm.write {
                                    //i.tag.append(tag)
                                //}
                            //}
                        //}
                    //}
                    // 画像解析をリクエスト
                    //let handler = VNImageRequestHandler(ciImage: ciImage)
                    // リクエストを実行
                    //do {
                        //try handler.perform([request])
                    //} catch {
                        //print(error)
                    //}
                //}
            //}
        //}
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == predictTableView {
            return predictArray.count
        } else {
            return dictionary.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == predictTableView {
            return 45
        } else {
            return 180
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == self.tableView {
            guard let cell = cell as? CustomTableViewCell else {
                return
            }
            cell.setCollectionDelegateDataSource(dataSourceDelegate: self, forRow: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == predictTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "predictCell", for: indexPath)
            cell.backgroundColor = .systemGray6
            cell.textLabel?.text = predictArray[indexPath.row]
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as? CustomTableViewCell else {
                fatalError("could not create tableview cell.")
            }
            cell.setUpContents(string: dictionary[indexPath.row].str)
            cell.collectionView.tag = indexPath.row
            
            if dictionary[indexPath.row].albums.count == 0 {
                cell.moreButton.isEnabled = false
            } else {
                cell.moreButton.isEnabled = true
            }
            
            cell.moreButton.tag = indexPath.row
            cell.moreButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
            return cell
        }
    }
    
    @objc func moreButtonAction(sender: UIButton) {
        let tag = sender.tag
        let albumTitle = dictionary[tag].str
        if albumTitle == "Photos" {
            performSegue(withIdentifier: "goPhotoLibrary", sender: nil)
        } else if albumTitle == "Favorite Photos" {
            for i in dictionary[tag].albums[0].album {
                selectedPhotos.append(i.imageID)
            }
            performSegue(withIdentifier: "goFavoritePhotos", sender: nil)
        } else {
            var idArray = [Int]()
            for i in dictionary[tag].albums {
                idArray.append(i.id)
            }
            ud.set(idArray, forKey: "view-albumID")
            ud.set(albumTitle, forKey: "albumNavigationTitle")
            performSegue(withIdentifier: "goAlbum", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == predictTableView {
            searchBar.resignFirstResponder()
            searchBar.text = predictArray[indexPath.row]
            searchBarSearchButtonClicked(searchBar)
            predictTableView.removeFromSuperview()
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dictionary.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == section {
            if dictionary[section].str == "Photos" || dictionary[section].str == "Favorite Photos" {
                if dictionary[section].albums.count != 0 {
                    if dictionary[section].albums[0].album.count <= 6 {
                        return dictionary[section].albums[0].album.count
                    } else {
                        return 6
                    }
                }
            } else {
                if dictionary[section].albums.count <= 6 {
                    return dictionary[section].albums.count
                } else {
                    return 6
                }
            }
        }
        return Int()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let albums = dictionary[indexPath.section].albums
        let albumTitle = dictionary[indexPath.section].str
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        if dictionary.count != 0 {
            if albumTitle == "Photos" || albumTitle == "Favorite Photos" {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
                    fatalError("could not create grid cell.")
                }
                if let requestID = cell.requestID {
                    imageManager.cancelImageRequest(requestID)
                }
                cell.imageView.image = nil
                let element = photoAssets.filter { $0.index == albums[0].album[indexPath.item].imageID}.first!
                cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width*2, height: cell.imageView.frame.height*2), contentMode: .aspectFill, options: options) { (image,info) in
                    cell.imageView.image = image
                }
                return cell
            } else {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCellViewController", for: indexPath) as? AlbumCellViewController else {
                    fatalError("could not create grid cell.")
                }
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
                                cell.label.text = albums[indexPath.item].name
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
                            cell.label.text = albums[indexPath.item].name
                        }
                    }
                } else {
                    cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width*2, height: cell.imageView1.frame.height*2), contentMode: .aspectFill, options: options) { (image1, info) in
                        cell.imageView1.image = image1
                        cell.imageView2.backgroundColor = .lightGray
                        cell.imageView3.backgroundColor = .darkGray
                        cell.label.text = albums[indexPath.item].name
                    }
                }

                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let albums = dictionary[indexPath.section].albums
        let title = dictionary[indexPath.section].str
        if title == "Photos" || title == "Favorite Photos" {
            ud.set(albums[0].album[indexPath.item].imageID, forKey: "photoID_value")
            performSegue(withIdentifier: "home-photo", sender: collectionView.cellForItem(at: indexPath))
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            let id = albums[indexPath.item].id
            ud.set(id, forKey: "view-albumContents")
            performSegue(withIdentifier: "goPhotos", sender: collectionView.cellForItem(at: indexPath))
        }
    }
}

