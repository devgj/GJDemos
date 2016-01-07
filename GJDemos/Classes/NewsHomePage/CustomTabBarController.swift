//
//  CustomTabBarController.swift
//  GJDemos
//
//  Created by GJ on 16/1/7.
//  Copyright © 2016年 GJ. All rights reserved.
//

import UIKit

class CustomTabBarItem: NSObject {
    var title: String
    var viewController: UIViewController
    init(title: String, viewController: UIViewController) {
        self.title = title
        self.viewController = viewController
        super.init()
    }
}

class ScaleLabel: UILabel {
    var scale: CGFloat = 0.0 {
        didSet {
            self.transform = CGAffineTransformMakeScale(1 + 0.3 * scale, 1 + 0.3 * scale)
            self.textColor = UIColor(red: scale, green: 0, blue: 0, alpha: 1)
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.textAlignment = .Center
        self.backgroundColor = UIColor.clearColor()
    }

    // http://stackoverflow.com/questions/25126295/swift-class-does-not-implement-its-superclasss-required-members
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol CustomTabBarControllerDataSource: NSObjectProtocol {
    func itemsOfCustomTabBarController(controller: CustomTabBarController) -> [CustomTabBarItem]
}

// 顶部滚动视图高度
private let titlesScrollViewHeight: CGFloat = 30

class CustomTabBarController: UIViewController {
    var viewControllers: [UIViewController]?
    weak var dataSource: CustomTabBarControllerDataSource? {
        didSet {
            if self.isViewLoaded() {
                self.setupChildVcs()
            }
        }
    }
    private var items: [CustomTabBarItem]?
    private lazy var titleLabels: [ScaleLabel] = []
    private weak var titlesScrollView: UIScrollView!
    private weak var contentScrollView: UIScrollView!

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.setupConstraints()
        
        if self.dataSource != nil {
            self.setupChildVcs()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollViewDidEndDecelerating(self.contentScrollView)
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        let titlesScrollView = UIScrollView()
        titlesScrollView.backgroundColor = UIColor.whiteColor()
        titlesScrollView.showsHorizontalScrollIndicator = false
        titlesScrollView.showsVerticalScrollIndicator = false
        self.view.addSubview(titlesScrollView)
        self.titlesScrollView = titlesScrollView
        
        let contentScrollView = UIScrollView()
        contentScrollView.backgroundColor = UIColor.grayColor()
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.pagingEnabled = true
        contentScrollView.delegate = self
        self.view.addSubview(contentScrollView)
        self.contentScrollView = contentScrollView
    }
    
    private func setupConstraints() {
        self.titlesScrollView.snp_makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(titlesScrollViewHeight)
        }
        
        self.contentScrollView.snp_makeConstraints { make in
            make.top.equalTo(self.titlesScrollView.snp_bottom)
            make.left.bottom.right.equalTo(self.view)
        }
    }
    
    // MARK: - Private Method
    private func setupChildVcs() {
        let items = self.dataSource?.itemsOfCustomTabBarController(self)
        if items == nil {
            return
        }
        assert(items!.count > 0, "func itemsOfCustomTabBarController(controller: CustomTabBarController) -> [CustomTabBarItem] 必须返回至少一个item")
        // 添加子控制器 添加titleLabels
        let labelH: CGFloat = titlesScrollViewHeight
        var labelX: CGFloat = 0
        for i in 0..<items!.count {
            let item = items![i]
            item.viewController.title = item.title
            self.addChildViewController(item.viewController)

            // 计算label宽度
            let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(18)]
            let titleSize = (item.title as NSString).sizeWithAttributes(attrs)
            let labelW = titleSize.width + 30
            
            // 添加label
            let label = ScaleLabel()
            label.font = attrs[NSFontAttributeName]
            label.text = item.title
            label.frame = CGRect(x: labelX, y: 0, width: labelW, height: labelH)
            labelX = CGRectGetMaxX(label.frame) + 0
            
            // 给label添加手势
            let tap = UITapGestureRecognizer(target: self, action: "titleLabelClick:")
            label.addGestureRecognizer(tap)
            label.userInteractionEnabled = true
            label.tag = i
            
            if i == 0 {
                label.scale = 1.0
            }
            
            self.titlesScrollView.addSubview(label)
            self.titleLabels.append(label)
        }
        let lastLabel = self.titleLabels.last
        if let lastLabel = lastLabel {
            self.titlesScrollView.contentSize = CGSize(width: CGRectGetMaxX(lastLabel.frame), height: 0)
        }
        self.contentScrollView.contentSize = CGSize(width: UIScreen.mainScreen().bounds.size.width * CGFloat(items!.count), height: 0)
    }
    
    // MARK: Event Responses
    func titleLabelClick(sender: UITapGestureRecognizer) {
        let index = sender.view!.tag
        let offset = CGPoint(x: self.contentScrollView.bounds.size.width * CGFloat(index), y: 0)
        self.contentScrollView.setContentOffset(offset, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension CustomTabBarController: UIScrollViewDelegate {
    // 人为拖动
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let height = scrollView.bounds.size.height
        let offsetX = scrollView.contentOffset.x
        let index = Int(offsetX / width)
        
        // 滚动label到相应位置
        let currentLabel = self.titleLabels[index]
        var titlesScrollViewOffsetX = currentLabel.center.x - width * 0.5
        
        if titlesScrollViewOffsetX < 0 {
            titlesScrollViewOffsetX = 0
        }
        let titlesScrollViewMaxOffSetX = self.titlesScrollView.contentSize.width - width
        if titlesScrollViewOffsetX > titlesScrollViewMaxOffSetX {
            titlesScrollViewOffsetX = titlesScrollViewMaxOffSetX
        }
        
        // 其他label取消缩放
        for label in self.titleLabels {
            if label != currentLabel {
                label.scale = 0.0
            }
        }
        
        self.titlesScrollView.setContentOffset(CGPoint(x: titlesScrollViewOffsetX, y: 0), animated: true)
        
        let viewController = self.childViewControllers[index]
        viewController.view.frame = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: height)
        self.contentScrollView.addSubview(viewController.view)
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let delta = scrollView.contentOffset.x / scrollView.bounds.size.width
        if delta < 0 || delta > CGFloat(self.titleLabels.count - 1) {
            return
        }
        let leftLabelIndex = Int(delta)
        let rightLabelIndex = leftLabelIndex + 1
        
        let leftLabelScale = CGFloat(rightLabelIndex) - delta
        let rightLabelScale = 1 - leftLabelScale
        
        let leftLabel = self.titleLabels[leftLabelIndex]
        let rightLabel : ScaleLabel? = rightLabelIndex == self.titleLabels.count ? nil : self.titleLabels[rightLabelIndex]
        
        leftLabel.scale = leftLabelScale
        rightLabel?.scale = rightLabelScale
    }
}
