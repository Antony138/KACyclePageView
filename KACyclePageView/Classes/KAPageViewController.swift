//
//  KAPageViewController.swift
//  KACyclePageView
//
//  Created by ZhihuaZhang on 2016/06/21.
//  Copyright © 2016年 Kapps Inc. All rights reserved.
//

import UIKit

protocol KAPageViewControllerDelegate {

    func WillBeginDragging()
    func didEndDragging()
    func didChangeToIndex(index: Int)
    func didScrolledWithContentOffsetX(x: CGFloat)

}

class KAPageViewController: UIPageViewController {

    
    var pageCount = 0
    
    private var currentIndex = 0
    
    var pageDelegate: KAPageViewControllerDelegate?
    var pageDataSource: KACyclePageViewDataSource?
    
    var dragging: Bool {
        get {
            let scrollView = view.subviews.compactMap { $0 as? UIScrollView }.first
            if let scrollView = scrollView {
                return scrollView.isDragging
            }
            return false
        }
    }
    
    var shouldScrollHeaderView = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        
        setupScrollView()
        
        guard let firstVC = pageDataSource?.viewControllerForPageAtIndex(index: currentIndex) else {
            return
        }

        firstVC.kaPageIndex = currentIndex

        setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
    }

    
    private func setupScrollView() {
        let scrollView = view.subviews.compactMap { $0 as? UIScrollView }.first
        scrollView?.scrollsToTop = false
        scrollView?.delegate = self
    }
    
    func displayControllerWithIndex(index: Int, direction: UIPageViewController.NavigationDirection, animated: Bool) {
        
        currentIndex = index
        shouldScrollHeaderView = false
        
        guard let vc = pageDataSource?.viewControllerForPageAtIndex(index: index) else {
            return
        }
        
        vc.kaPageIndex = index
        
        let nextViewControllers: [UIViewController] = [vc]
        
        setViewControllers(nextViewControllers, direction: direction, animated: animated) {[weak self] (_) in
            self?.shouldScrollHeaderView = true
        }
    }
    
    // MARK: - Support

    
    private func nextViewController(current: UIViewController, isAfter: Bool) -> UIViewController? {
        if pageCount < 2 {
            return nil
        }
        
        var index = currentIndex
        
        index = isAfter ? index + 1 : index - 1
        
        if index < 0 {
            index = pageCount - 1
        } else if index == pageCount {
            index = 0
        }
        
        if index >= 0 && index < pageCount {
            let vc = pageDataSource?.viewControllerForPageAtIndex(index: index)
            vc?.kaPageIndex = index
            
            return vc
        }
        return nil
    }
    
}

// MARK: - UIScrollViewDelegate

extension KAPageViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pageDelegate?.WillBeginDragging()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldScrollHeaderView {
            let scrollOffsetX = scrollView.contentOffset.x - view.frame.width
            
            pageDelegate?.didScrolledWithContentOffsetX(x: scrollOffsetX)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageDelegate?.didEndDragging()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            pageDelegate?.didEndDragging()
        }
    }
}

// MARK: - UIPageViewController

extension KAPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = viewControllers?.first?.kaPageIndex else {
            return
        }
        
        currentIndex = index
        
        pageDelegate?.didChangeToIndex(index: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nextViewController(current: viewController, isAfter: true)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nextViewController(current: viewController, isAfter: false)
    }

}

private var kaPageIndexAssociationKey = 0

public extension UIViewController {
    
    var kaPageIndex: Int {
        get {
            return objc_getAssociatedObject(self, &kaPageIndexAssociationKey) as! Int
        }
        
        set(newValue) {
            objc_setAssociatedObject(self, &kaPageIndexAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
}
