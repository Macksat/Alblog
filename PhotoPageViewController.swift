//
//  PhotoPageViewController.swift
//  Alblog
//
//  Created by Sato Masayuki on 2021/11/06.
//

import UIKit
import Photos

class PhotoPageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var controllers = [UIViewController]()
    var currentPage = 0
    var initialPage = Int()
    let ud = UserDefaults.standard
    let imageManager = PHImageManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.delegate = self
        self.dataSource = self
        
        let idArray = ud.array(forKey: "photoList-IDArray") as! [Int]
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        for (index, i) in idArray.enumerated() {
            if i == ud.integer(forKey: "photoID_value") {
                initialPage = index
            }
            let vc = FullScreenViewController()
            let element = photoAssets.filter { $0.index == i }.first!
            imageManager.requestImage(for: element.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, _ in
                vc.imageView.image = image
                self.controllers.append(vc)
            }
        }
        
        self.setViewControllers([controllers[initialPage]], direction: .forward, animated: true, completion: nil)
        
        self.view.backgroundColor = .black
    }
    
    override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey : Any]? = nil) {
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: options
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = controllers.firstIndex(of: viewController)
        if index == 0 {
            return nil
        } else {
            return controllers[index!-1]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = controllers.firstIndex(of: viewController)
        if index == controllers.count - 1 {
            return nil
        } else {
            return controllers[index!+1]
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return controllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentPage
    }
}
