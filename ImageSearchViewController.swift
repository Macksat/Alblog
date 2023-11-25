//
//  ImageSearchViewController.swift
//  ImageSearchViewController
//
//  Created by Sato Masayuki on 2021/09/05.
//

import UIKit

class ImageSearchViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let ud = UserDefaults.standard

    @IBOutlet weak var objectCollectionView: UICollectionView!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        objectCollectionView.delegate = self
        objectCollectionView.dataSource = self
        resultCollectionView.delegate = self
        resultCollectionView.dataSource = self
        
        objectCollectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        resultCollectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        
        let layout1 = UICollectionViewFlowLayout()
        layout1.itemSize = CGSize(width: (self.view.frame.width-60)/2, height: (self.view.frame.width-40)*4/10)
        layout1.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        resultCollectionView.collectionViewLayout = layout1
        
        self.view.backgroundColor = .systemGray6
        objectCollectionView.backgroundColor = .systemGray6
        resultCollectionView.backgroundColor = .systemGray6
    }
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)) -> ImageSearchViewController {
        let controller = storyboard.instantiateViewController(withIdentifier: "ImageSearchViewController") as! ImageSearchViewController
        return controller
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == objectCollectionView {
            return objectArray.count
        } else {
            return webImageArray.count
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
                fatalError("Could not create cell.")
            }
            if let url = URL(string: webImageArray[indexPath.item]) {
                let req = URLRequest(url: url)
                let task = URLSession.shared.dataTask(with: req, completionHandler: {data, response, error in
                    if let data = data {
                        if let anImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                if imageTitleArray.count != 0 {
                                    cell.setUpContents(image: anImage, string: imageTitleArray[indexPath.item])
                                }
                            }
                        }
                    }
                })
                task.resume()
            }
            
            return cell
        }        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == objectCollectionView {
            let string = objectArray[indexPath.item].identifier
            let parameter = ["key": apiKey, "cx": cx, "searchType": searchType, "q": string]
            let requestURL = createRequestURL(parameter: parameter)
            request(requestURL: requestURL) { result in
                DispatchQueue.main.async {
                    self.resultCollectionView.reloadData()
                }
            }
        } else {
            ud.set(webImageArray[indexPath.item], forKey: "webImage_value")
            ud.set(imageTitleArray[indexPath.item], forKey: "webTitle_value")
            ud.set(webURLArray[indexPath.item], forKey: "webURL_value")
            performSegue(withIdentifier: "imageResults-content", sender: nil)
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
}
