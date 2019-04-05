//
//  KACyclePageView.swift
//  KACyclePageView
//
//  Created by ZhihuaZhang on 2016/06/21.
//  Copyright © 2016年 Kapps Inc. All rights reserved.
//

import UIKit

public protocol KACyclePageViewDataSource {
    
    func numberOfPages() -> Int
    func viewControllerForPageAtIndex(index: Int) -> UIViewController
    func titleForPageAtIndex(index: Int) -> String

    //TODO: setup by Config or delegate
    func colorForCurrentTitle() -> UIColor
    func colorForDefaultTitle() -> UIColor
    
}

let CountForCycle: Int = 1000

private struct UX {
    static let labelMargin: CGFloat = 8
}

public class KACyclePageView: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    open lazy var selectedBar: UIView = { [unowned self] in
        let bar  = UIView(frame: CGRect(x: 0, y: collectionView.frame.size.height - CGFloat(self.selectedBarHeight), width: 0, height: CGFloat(self.selectedBarHeight)))
        bar.layer.zPosition = 9999
        bar.backgroundColor = .black
        return bar
        }()
    
    internal var selectedBarHeight: CGFloat = 4 {
        didSet {
            updateSelectedBarYPosition()
        }
    }
    
    private var pageViewController: KAPageViewController!
    
    private let MinCycleCellCount = 4
    
    private var cellWidth: CGFloat {
        return view.frame.width / CGFloat(visibleCellCount)
    }
    
    private var collectionViewContentOffsetX: CGFloat = 0.0
    
    private var pageIndex: Int = 0
    private var headerIndex: Int = CountForCycle
    
    private var pageCount = 0
    
    private var shouldCycle: Bool {
        get {
            return false
        }
    }
    
    private var scrollPostition: UICollectionView.ScrollPosition {
        get {
//            return pageCount > MinCycleCellCount ? .CenteredHorizontally : .None
            return .centeredHorizontally
        }
    }
    
    private var visibleCellCount: Int {
        get {
            return min(MinCycleCellCount, pageCount)
        }
    }
    
    var dataSource: KACyclePageViewDataSource?
    
    //for launch
    var needUpdateBottomBarViewWidth = true
    
    //for after drag header
    var needScrollToCenter = false
    
    public class func cyclePageView(dataSource: AnyObject) -> KACyclePageView {
        let podBundle = Bundle(for: self.classForCoder())
        let bundleURL = podBundle.url(forResource: "KACyclePageView", withExtension: "bundle")!
        let bundle = Bundle(url: bundleURL)
        let storyboard = UIStoryboard(name: "KACyclePageView", bundle: bundle)
        let vc = storyboard.instantiateInitialViewController() as! KACyclePageView

        vc.dataSource = dataSource as? KACyclePageViewDataSource
        
        vc.pageCount = vc.dataSource!.numberOfPages()
        
        return vc
    }
    
    private func updateSelectedBarYPosition() {
        var selectedBarFrame = selectedBar.frame
        selectedBarFrame.origin.y = collectionView.frame.size.height - selectedBarHeight
        selectedBarFrame.size.height = selectedBarHeight
        selectedBar.frame = selectedBarFrame
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        collectionView.addSubview(selectedBar)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let indexPath = NSIndexPath(item: headerIndex, section: 0)
        
        if shouldCycle {
            collectionView.scrollToItem(at: indexPath as IndexPath, at: scrollPostition, animated: false)
        } else {
            
        }
    }
    
    // MARK: - Navigation

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SeguePageView" {
            pageViewController = segue.destination as? KAPageViewController
            pageViewController.pageDelegate = self
            pageViewController.pageCount = pageCount
            pageViewController.pageDataSource = dataSource
        }
    }
    
    // MARK: - support
    
    private func updateIndex(index: Int) {
        if shouldCycle {
            headerIndex += (index - pageIndex)
            pageIndex = index

            let indexPath = NSIndexPath(item: headerIndex, section: 0)

            if shouldCycle {
                collectionView.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: false)
            } else {
                
            }
            
            collectionView.reloadData()
            
            collectionViewContentOffsetX = 0.0
        } else {
//            currentIndex = index
        }
    }

    private func scrollWithContentOffsetX(contentOffsetX: CGFloat) {
        
        if contentOffsetX == 0 {
            return
        }
        
        let currentIndexPath = NSIndexPath(item: headerIndex, section: 0)
        
        if self.collectionViewContentOffsetX == 0.0 {
            self.collectionViewContentOffsetX = self.collectionView.contentOffset.x
        }
        
        if let currentCell = self.collectionView.cellForItem(at: currentIndexPath as IndexPath) as? TitleCell {
            
            let distance = currentCell.frame.width
            let scrollRate = contentOffsetX / self.view.frame.width
            let scroll = scrollRate * distance
            self.collectionView.contentOffset.x = self.collectionViewContentOffsetX + scroll
            
            let nextIndex = contentOffsetX > 0 ? headerIndex + 1 : headerIndex - 1
            let nextIndexPath = NSIndexPath(item: nextIndex, section: 0)

            guard let nextCell = collectionView.cellForItem(at: nextIndexPath as IndexPath) as? TitleCell else {
                return
            }
            
            //update bar width
            
            guard let currentColor = dataSource?.colorForCurrentTitle(), let defaultColor = dataSource?.colorForDefaultTitle() else {
                return
            }
            
            nextCell.titleLabel.textColor = colorForProgress(oldColor: defaultColor, newColor: currentColor, progress: abs(scrollRate))
            currentCell.titleLabel.textColor = colorForProgress(oldColor: currentColor, newColor: defaultColor, progress: abs(scrollRate))
        }
    }
    
    private func colorForProgress(oldColor: UIColor, newColor: UIColor, progress: CGFloat) -> UIColor {
        guard let old = oldColor.coreImageColor, let new = newColor.coreImageColor else {
            return oldColor
        }
        
        let newR = (1 - progress) * old.red + progress * new.red
        let newG = (1 - progress) * old.green + progress * new.green
        let newB = (1 - progress) * old.blue + progress * new.blue
        
        return UIColor(red: newR, green: newG, blue: newB, alpha: 1.0)
    }
    
    private func needUpdateTitleColor(contentOffsetX: CGFloat) -> Bool {
        return contentOffsetX > view.frame.width / 2 || contentOffsetX < -view.frame.width / 2
    }

    private func moveBottomBar(toCell cell: TitleCell? = nil) {
        var targetCell: TitleCell? = cell
        if targetCell == nil {
            targetCell = collectionView.cellForItem(at: NSIndexPath(item: headerIndex, section: 0) as IndexPath) as? TitleCell
        }
        
        if targetCell == nil {
            let cells = collectionView.visibleCells as! [TitleCell]
            
            
            let c = cells.filter {
                if let indexPath = collectionView.indexPath(for: $0) {
                    return pageIndexFromHeaderIndex(index: indexPath.item) == pageIndex
                }
                
                return false
            }
            
            targetCell = c.first
        }
    }

    private func pageIndexFromHeaderIndex(index: Int) -> Int {
        let i = (index - CountForCycle) % pageCount
        
        if i < 0 {
            return i + pageCount
        }
        
        return i
    }
    
    
    private func scrollToPageIndex() {
        headerIndex = CountForCycle + pageIndex
        let indexPath = NSIndexPath(item: headerIndex, section: 0)
        
        if shouldCycle {
            collectionView.scrollToItem(at: indexPath as IndexPath, at: scrollPostition, animated: false)
        } else {
            
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        needScrollToCenter = true
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if scrollView.isDragging {
            moveBottomBar()
        }
    }
    
}

// MARK: - UICollection

extension KACyclePageView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = cellWidth
        
        return CGSize(width: width, height: collectionView.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shouldCycle ? pageCount * CountForCycle * 2 : pageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TitleCell", for: indexPath as IndexPath) as! TitleCell
        
        let cycledIndex = pageIndexFromHeaderIndex(index: indexPath.item)
        
        let titleIndex = shouldCycle ? cycledIndex : indexPath.item
        
        let title = dataSource?.titleForPageAtIndex(index: titleIndex)
        
        cell.titleLabel.text = title
        
        if needUpdateBottomBarViewWidth && cycledIndex == pageIndex {
            cell.titleLabel.sizeToFit()
            needUpdateBottomBarViewWidth = false
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let newPageIndex = pageIndexFromHeaderIndex(index: indexPath.item)
        
        if newPageIndex == pageIndex || pageViewController.dragging {
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = indexPath.item > headerIndex ? .forward : .reverse
        
        pageViewController.displayControllerWithIndex(index: newPageIndex, direction: direction, animated: true)
        
        if let visableCells = collectionView.visibleCells as? [TitleCell] {
            for cell in visableCells {
                cell.titleLabel.textColor = dataSource?.colorForDefaultTitle()
            }
        }
        
        pageIndex = newPageIndex
        headerIndex = indexPath.item
        
        let nextCell = collectionView.cellForItem(at: indexPath as IndexPath) as! TitleCell
        
        nextCell.titleLabel.textColor = dataSource?.colorForCurrentTitle()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        if shouldCycle {
            collectionView.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: true)
        } else {
            
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cycledIndex = pageIndexFromHeaderIndex(index: indexPath.item)
        
        (cell as? TitleCell)?.titleLabel.textColor = cycledIndex == pageIndex ? dataSource?.colorForCurrentTitle() : dataSource?.colorForDefaultTitle()
    }
    
}

// MARK: - KAPageViewControllerDelegate

extension KACyclePageView: KAPageViewControllerDelegate {
    func WillBeginDragging() {
        collectionView.isScrollEnabled = false
        
        if needScrollToCenter {
            scrollToPageIndex()
            
            needScrollToCenter = false
        }
    }
    
    func didEndDragging() {
        print(#function)
        
        collectionView.isScrollEnabled = true
    }
    
    func didChangeToIndex(index: Int) {
        updateIndex(index: index)
    }
    
    func didScrolledWithContentOffsetX(x: CGFloat, fromIndex: Int, toIndex: Int, progressPercentage: CGFloat) {
        if shouldCycle {
            scrollWithContentOffsetX(contentOffsetX: x)
        } else {
            // Reference: XLPagerTabStrip
//            selectedIndex = progressPercentage > 0.5 ? toIndex : fromIndex
            
            guard let numberOfItems = dataSource?.numberOfPages() else { return }
            let fromFrame = collectionView.layoutAttributesForItem(at: IndexPath(item: fromIndex, section: 0))!.frame
            
            var toFrame: CGRect
            
            if toIndex < 0 || toIndex > numberOfItems - 1 {
                if toIndex < 0 {
                    let cellAtts = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))
                    toFrame = cellAtts!.frame.offsetBy(dx: -cellAtts!.frame.size.width, dy: 0)
                } else {
                    let cellAtts = collectionView.layoutAttributesForItem(at: IndexPath(item: (numberOfItems - 1), section: 0))
                    toFrame = cellAtts!.frame.offsetBy(dx: cellAtts!.frame.size.width, dy: 0)
                }
            } else {
                toFrame = collectionView.layoutAttributesForItem(at: IndexPath(item: toIndex, section: 0))!.frame
            }
            
            var targetFrame = fromFrame
            targetFrame.size.height = selectedBar.frame.size.height
            targetFrame.size.width += (toFrame.size.width - fromFrame.size.width) * progressPercentage
            targetFrame.origin.x += (toFrame.origin.x - fromFrame.origin.x) * progressPercentage
            selectedBar.frame = CGRect(x: targetFrame.origin.x, y: selectedBar.frame.origin.y, width: targetFrame.size.width, height: selectedBar.frame.size.height)
            
            var targetContentOffset: CGFloat = 0.0
//            if contentSize.width > frame.size.width {
                let toContentOffset = contentOffsetForCell(withFrame: toFrame, andIndex: toIndex)
                let fromContentOffset = contentOffsetForCell(withFrame: fromFrame, andIndex: fromIndex)
                
                targetContentOffset = fromContentOffset + ((toContentOffset - fromContentOffset) * progressPercentage)
//            }
            
            collectionView.setContentOffset(CGPoint(x: targetContentOffset, y: 0), animated: false)
        }
    }
    
    private func contentOffsetForCell(withFrame cellFrame: CGRect, andIndex index: Int) -> CGFloat {
        var alignmentOffset: CGFloat = 0.0
        
        alignmentOffset = (collectionView.frame.size.width - cellFrame.size.width) * 0.5
        
        var contentOffset = cellFrame.origin.x - alignmentOffset
        contentOffset = max(0, contentOffset)
        contentOffset = min(collectionView.contentSize.width - collectionView.frame.size.width, contentOffset)
        return contentOffset
    }
}

// MARK: - TitleCell

class TitleCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    
    var titleLabelWidthWithMargin: CGFloat {
        return titleLabel.frame.width + 2 * UX.labelMargin
    }
}

extension UIColor {
    
    var coreImageColor: CoreImage.CIColor? {
        return CoreImage.CIColor(color: self)
    }
    
}
