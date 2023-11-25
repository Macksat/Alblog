//
//  WebContentsViewController.swift
//  WebContentsViewController
//
//  Created by Sato Masayuki on 2021/08/24.
//

import UIKit
import RealmSwift
import CoreML
import Vision
import Photos

class WebContentsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var urlArray = [String]()
    var imageArrary = [String]()
    var titleArray = [String]()
    let ud = UserDefaults.standard
    let realm = try! Realm()
    let apiKey = "AIzaSyAnpE79AGkv98bYkaMdzSW0Z3p0GrMPc6s"
    let cx = "20471edf0111f889c"
    let url = "https://www.googleapis.com/customsearch/v1"
    let searchType = "image"
    var searchText = String()

    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    @IBAction func downloadButton(_ sender: Any) {
        let link = Link()
        link.title = ud.string(forKey: "webTitle_value")!
        link.image = try! NSData(contentsOf: URL(string: ud.string(forKey: "webImage_value")!)!)
        link.url = ud.string(forKey: "webURL_value")!
        do {
            let webImageData = try Data(contentsOf: URL(string: ud.string(forKey: "webImage_value")!)!)
            let webImage = UIImage(data: webImageData)
            UIImageWriteToSavedPhotosAlbum(webImage!, nil, nil, nil)
            photoAssets.removeAll()
            let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: nil)
            assets.enumerateObjects({ [weak self] (asset, index, stop) -> Void in
                autoreleasepool {
                    guard let wself = self else {
                        return
                    }
                    let element = (asset, index)
                    photoAssets.append(element)
                    if photoAssets.count == assets.count {
                        DispatchQueue.main.async {
                            let photo = Photo()
                            photo.imageID = photoAssets.count
                            let memos = Memos()
                            memos.id = Memos.newID()
                            memos.number = 0
                            memos.link.append(link)
                            photo.memos.append(memos)
                            photo.url = wself.ud.string(forKey: "webURL_value")!
                            let tag = Tag()
                            tag.tag = wself.ud.string(forKey: "searchBarText_value")!
                            photo.tag.append(tag)
                            try! wself.realm.write {
                                wself.realm.add(photo)
                            }
                            
                            let result = wself.realm.objects(Album.self)
                            for i in result {
                                if i.name == "" {
                                    try! wself.realm.write {
                                        i.album.append(photo)
                                    }
                                }
                            }
                        }
                    }
                }
            })
        } catch {
            print("Error when adding photo to realm.")
        }
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "saveImage")
        imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 80, height: self.view.frame.width - 80)
        imageView.layer.position = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/2)
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.view.addSubview(imageView)
        }, completion: nil)
        
        UIView.animate(withDuration: 0.25, delay: 1.0, options: UIView.AnimationOptions.allowUserInteraction, animations: {
            // Viewを見えなくする
            imageView.alpha = 0.05
        }) { (completed) in
            // Animationが完了したら親Viewから削除する
            imageView.removeFromSuperview()
        }
        
        downloadButtonBool()
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var webButton: UIButton!
    @IBAction func webButton(_ sender: Any) {
        performSegue(withIdentifier: "goWebView", sender: nil)
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var objectCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        objectArray.removeAll()

        collectionView.delegate = self
        collectionView.dataSource = self
        objectCollectionView.delegate = self
        objectCollectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        objectCollectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.view.frame.width-60)/2, height: (self.view.frame.width-40)*4/10)
        self.collectionView.collectionViewLayout = layout
        
        downloadButtonBool()
        titleLabel.text = ud.string(forKey: "webTitle_value")
        imageView.layer.cornerRadius = 15
        imageViewHeight.constant = (self.view.frame.width - 40) * 3 / 4
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let url = URL(string: ud.string(forKey: "webImage_value")!)!
        let req = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: req, completionHandler: {data, response, error in
            if let data = data {
                if let anImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.imageView.image = anImage
                        self.detectImageObject(image: anImage)
                        self.classifyObject(image: anImage)
                        let parameter = ["key": self.apiKey, "cx": self.cx, "searchType": self.searchType, "q": self.searchText]
                        let requestURL = self.createRequestURL(parameter: parameter)
                        self.request(requestURL: requestURL) { result in
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    func downloadButtonBool() {
        let webURL = ud.string(forKey: "webURL_value")!
        let photos = realm.objects(Photo.self)
        var bool = false
        for i in photos {
            if i.url == webURL {
                bool = true
            }
        }
        if bool == true {
            downloadButton.isEnabled = false
        } else {
            downloadButton.isEnabled = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == objectCollectionView {
            return objectArray.count
        } else {
            return imageArrary.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == objectCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
                fatalError("Could not create cell.")
            }
            
            cell.setUpContents(image: UIImage(named: "saveImage")!, string: objectArray[indexPath.item].identifier)
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
                fatalError("could not create grid cell.")
            }
            do {
                let imageData = try Data(contentsOf: URL(string: imageArrary[indexPath.item])!)
                cell.setUpContents(image: UIImage(data: imageData)!, string: titleArray[indexPath.item])
            } catch {
                print("Error when attatching photos to cell.")
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView == objectCollectionView {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 2
            cell?.layer.borderColor = UIColor.systemBlue.cgColor
            searchText = objectArray[indexPath.item].identifier
            let parameter = ["key": apiKey, "cx": cx, "searchType": searchType, "q": searchText]
            let requestURL = createRequestURL(parameter: parameter)
            request(requestURL: requestURL) { result in
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        } else {
            ud.set(imageArrary[indexPath.item], forKey: "webImage_value")
            ud.set(titleArray[indexPath.item], forKey: "webTitle_value")
            ud.set(urlArray[indexPath.item], forKey: "webURL_value")
            present(self, animated: true, completion: nil)
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
                //try handler.perform([request])
            //} catch {
                //print(error)
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
        
        let requestURL = url + "?" + parameterString
        return requestURL
    }
    
    func parseData(items: [Any], resultHandler: @escaping (([String]?) -> Void)) {
        for i in items {
            // レスポンスデータから画像情報を取得する
            guard let item = i as? [String: Any], let imageURL = item["link"] as? String, let title = item["title"] as? String, let image = item["image"] as? [String: Any], let url = image["contextLink"] as? String else {
                resultHandler(nil)
                return
            }
            
            imageArrary.append(imageURL)
            titleArray.append(title)
            urlArray.append(url)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        ud.set(titleArray[indexPath.item], forKey: "webTitle_value")
        ud.set(imageArrary[indexPath.item], forKey: "webImage_value")
        ud.set(urlArray[indexPath.item], forKey: "webURL_value")
        titleArray.removeAll()
        imageArrary.removeAll()
        urlArray.removeAll()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "WebContentViewController")
        self.show(vc, sender: nil)
    }
    
    @IBAction func imageViewAction(_ sender: Any) {
        ud.set("webVC", forKey: "segue_value")
        performSegue(withIdentifier: "web-full", sender: nil)
    }
}
