//
//  SwipeViewController.swift
//  Lifide
//
//  Created by Masayuki Sato on 2020/10/24.
//  Copyright © 2020 CRoW. All rights reserved.
//

import UIKit

var pageViewArray:[(label:String, text:String, image:String)] = []

class SwipeViewController: UIPageViewController, UIPageViewControllerDelegate, UNUserNotificationCenterDelegate {

    var controllers = [UIViewController]()
    var currentPage = 0
    let ud = UserDefaults.standard
    let doneButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        for a in pageViewArray {
            let i = PageViewContentViewController()
            
            i.label.text = a.label
            i.textView.text = a.text
            i.imageView.image = UIImage(named: a.image)
            
            controllers.append(i)
        }
        
        doneButton.frame = CGRect(x: view.frame.width - 80, y: 40, width: 60, height: 20)
        doneButton.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        doneButton.setTitleColor(UIColor(red: 0.886, green: 0.196, blue: 0.494, alpha: 1), for: .normal)
        doneButton.addTarget(self, action: #selector(doneAction(_:)), for: .touchUpInside)
        view.addSubview(doneButton)
        
        self.setViewControllers([controllers[0]], direction: .forward, animated: true, completion: nil)
        
        self.view.backgroundColor = .systemBackground
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        doneButton.frame = CGRect(x: view.frame.width - 80, y: 40, width: 60, height: 20)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if ud.bool(forKey: "firstNotificationBool") != true {
            ud.set(true, forKey: "firstNotificationBool")
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                
            }
        }
    }
    
    @objc func doneAction(_ button: UIButton) {
        if ud.bool(forKey: "firstBool") != true {
            ud.set(true, forKey: "firstBool")
        }
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
}

extension SwipeViewController: UIPageViewControllerDataSource {
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

class PageViewContentViewController: UIViewController {
    
    let imageView = UIImageView()
    let label = UILabel()
    let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.font = UIFont.boldSystemFont(ofSize: 24)
        textView.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        textView.textColor = .label
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        
        imageView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: (view.frame.height/2) - 20)
        imageView.contentMode = .scaleAspectFit
        label.frame = CGRect(x: 20, y: 90 + view.frame.height/2, width: view.frame.width - 40, height: ((view.frame.height/2) - 40)/6)
        textView.frame = CGRect(x: 20, y: 100/3 + view.frame.height*7/12 + 50, width: view.frame.width - 40, height: (view.frame.height*5/12) - 100/3)
        
        view.addSubview(label)
        view.addSubview(textView)
        view.addSubview(imageView)
        
        textView.isUserInteractionEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: (view.frame.height/2) - 20)
        label.frame = CGRect(x: 20, y: 90 + view.frame.height/2, width: view.frame.width - 40, height: ((view.frame.height/2) - 40)/6)
        textView.frame = CGRect(x: 20, y: 100/3 + view.frame.height*7/12 + 50, width: view.frame.width - 40, height: (view.frame.height*5/12) - 100/3)
    }
}
