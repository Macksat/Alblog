//
//  FullScreenViewController.swift
//  FullScreenViewController
//
//  Created by Sato Masayuki on 2021/08/24.
//

import UIKit
import Photos

class FullScreenViewController: UIViewController, UIScrollViewDelegate {
    
    let ud = UserDefaults.standard
    var bool = Bool()
    var imageManager = PHImageManager()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        
        let webImage = ud.string(forKey: "webImage_value")
        let segue = ud.string(forKey: "segue_value")
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        if segue == "photoVC" {
            let element = photoAssets.filter { $0.index == ud.integer(forKey: "photoID_value") }.first!
            imageManager.requestImage(for: element.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
                self.imageView.image = image
            }
        } else if segue == "webVC" {
            let url = URL(string: webImage!)!
            let req = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: req, completionHandler: {data, response, error in
                if let data = data {
                    if let anImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.imageView.image = anImage
                        }
                    }
                }
            })
            task.resume()
        }
        
        navigationController?.navigationBar.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarController?.tabBar.isHidden = true
        bool = true
        self.view.backgroundColor = .black
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @IBAction func imageViewTapped(_ sender: Any) {
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: {
            if self.bool == false {
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.tabBarController?.tabBar.isHidden = true
                self.view.backgroundColor = .black
                self.bool = true
            } else {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                self.tabBarController?.tabBar.isHidden = false
                self.view.backgroundColor = .systemBackground
                self.bool = false
            }
        }, completion: nil)
    }
}
