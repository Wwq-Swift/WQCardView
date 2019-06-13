//
//  WQCardView.swift
//  WQCardView
//
//  Created by 王伟奇 on 2019/4/22.
//  Copyright © 2019 王伟奇. All rights reserved.
//

import UIKit

public enum WQCardCellSwipeDirection {
    case left, right
}

/// 卡片视图数据源
public protocol WQCardViewDataSource: class {
    /// 视图中有多少张卡片
    func numberOfItems(in cardView: WQCardView) -> Int
    /// 对应位置的卡片
    func cardView(_ cardView: WQCardView, itemAt index: Int) -> WQCardViewBaseItem
}

/// 卡片视图的状态代理
public protocol WQCardViewDelegate: class {
    
}

extension WQCardViewDelegate {
    func cardView(_ cardView: WQCardView, didRemove item: WQCardViewBaseItem, forAt index: Int) {
        print(index)
    }
    
    /// 卡片完成显示 (item 当前界面上显示的最底部的item)
    func cardView(_ cardView: WQCardView, didEndDisplaying item: WQCardViewBaseItem, forAt index: Int) {}
    /// 卡片完成移除
    
    /// 卡片item全部被移除
    func cardView(_ cardView: WQCardView, didRemoveLast item: WQCardViewBaseItem) {}
    /// 卡片移动
    func cardView(_ cardView: WQCardView, didMove item: WQCardViewBaseItem, forAt index: Int) {}
    /// 点击了卡片
    func cardView(_ cardView: WQCardView, didSelectItemAt index: Int) {}
}

/// 卡片视图
public class WQCardView: UIView {

    public weak var dataSource: WQCardViewDataSource!
    public weak var delegate: WQCardViewDelegate?
    
    /// 可见的卡片数量
    public var visibleCount = 3
    /// 当前可见的最大索引 (可看见的最底层的索引)
    private var visibleMaxIndex = 0
    /// 记录翻页的次数
    private var moveCount = 0
    
    /// 行间距
    public var lineSpacing: CGFloat = 10
    /// 列间距
    public var interitemSpacing: CGFloat = 10
    /// 侧滑最大角度
    public var maxAngle: CGFloat = 15
    /// 最大移除距离
    public var maxRemoveDistance: CGFloat = UIScreen.width / 4
    /// 是否需要透明
    public var needAlpha = true
    
    private var containerView: UIView!

    /// 复用的id 字典
    private var reusableItemsDic: [String: [WQCardViewBaseItem]] = [:]
    /// 注册的cell 的类
    private var itemClassDic: [String: AnyClass?] = [:]
    
    /// 当前可见的 item
    private var visibleItems: [WQCardViewBaseItem] {
        get {
            if let items = containerView.subviews as? [WQCardViewBaseItem] {
                return items
            }
            return []
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        containerView.backgroundColor = .yellow
        addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 更新数据 (默认没有动画)
    public func reloadData(with animated: Bool = false) {
        
        moveCount = 0
        visibleMaxIndex = 0
        /// 遍历缓存池中所有 item 并移除
        for var reusableItems in reusableItemsDic {
            reusableItems.value.removeAll()
        }
        
        let maxCount = dataSource?.numberOfItems(in: self) ?? 0
        /// 取展示在界面的 item 个数
        let showNumber = min(maxCount, visibleCount)
        for index in 0..<showNumber {
            createItemforCardView(in: index)
        }
        updateLayoutVisibleItem(with: animated)
    }

//    var cardItemType = CardViewItem.self
    /// 注册Cell
    public func register(_ itemClass: AnyClass?, forItemReuseIdentifier identifier: String) {
        itemClassDic[identifier] = itemClass
    }
    
    /// 获取复用的 Item (运用享元设计模式)
    open func dequeueReusableItem(withIdentifier identifier: String, for index: Int) -> WQCardViewBaseItem? {
        /// 从缓存池中判断是否存在item
        var resusableItems = reusableItemsDic[identifier]
        if let item = resusableItems?.first {
            resusableItems?.removeFirst()
            item.index = index
            return item
        }
        /// 根据 anyClass 去创建对象
        if let itemClass = itemClassDic[identifier], let type = itemClass as? WQCardViewBaseItem.Type {
            let item = type.init(reuseIdentifier: identifier)
            item.index = index
            return item
        }
        return nil
    }
    
    /// 获取 对应位置的item 卡片
    open func itemForIndex(at index: Int) -> WQCardViewBaseItem? {
        return nil
    }
    
    /// 获取当前最顶层现实的 item 的索引
    func currentTopItemIndex() -> Int {
        return visibleMaxIndex - visibleItems.count
    }
    
    /// 获取 item 对应的位置
    open func indexOf(item: WQCardViewBaseItem) -> Int? {
        /// 目前可见的 index 信息
        guard let visibleIndex = visibleItems.firstIndex(of: item) else {
            return nil
        }
        return visibleMaxIndex - visibleIndex
    }
    
    /// 滑动移除最顶层的卡片
    open func removeTopItemFromCardView(by direction: WQCardCellSwipeDirection) {
        guard !visibleItems.isEmpty else { return }
        let topItem = visibleItems.last!
        topItem.removeFromSuperView(by: direction)
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        reloadData()
    }
}

extension WQCardView {
    /// 创建 item
    private func createItemforCardView(in index: Int) {
        let item = dataSource.cardView(self, itemAt: index)
        item.index = index
        item.delegate = self
        let showCount = CGFloat(visibleCount - 1)
        let widt = bounds.width
        let heiht = bounds.height - (showCount * interitemSpacing)
        item.frame = CGRect(x: 0, y: 0, width: widt, height: heiht)
        containerView.insertSubview(item, at: 0)
        containerView.layoutIfNeeded()
        visibleMaxIndex = index
        
        let minWidth = bounds.width - 2 * lineSpacing * showCount
        let minHeight = bounds.height - 2 * interitemSpacing * showCount
        let minWScale = minWidth / bounds.width
        let minHScale = minHeight / bounds.height
        let yOffset = (interitemSpacing / minHScale) * 2 * showCount
        let scaleTransform = CGAffineTransform(scaleX: minWScale, y: minHScale)
        /// 大小变换
        let transform = scaleTransform.translatedBy(x: 0, y: yOffset)
        item.transform = transform
    }
    /// 更新可见的 item 布局
    private func updateLayoutVisibleItem(with animate: Bool) {
        let showCount = CGFloat(visibleCount - 1)
        let minWidth = bounds.width - 2 * lineSpacing * showCount
        let minHeight = bounds.height - 2 * interitemSpacing * showCount
        let minWScale = minWidth / bounds.width
        let minHScale = minHeight / bounds.height
        let itemWScale = (1.0 - minWScale) / showCount
        let itemHScale = (1.0 - minHScale) / showCount
        let count = visibleItems.count  /// 当前界面可见的 item 数目
        for i in 0..<count {
            let showIndex = CGFloat(count - i - 1)
            let wScale = 1 - showIndex * itemWScale
            let hScale = 1 - showIndex * itemHScale
            let offsetY = (interitemSpacing / hScale) * 2 * showIndex
            let scaleTransform = CGAffineTransform(scaleX: wScale, y: hScale)
            let transform = scaleTransform.translatedBy(x: 0, y: offsetY)
            let item = visibleItems[i]
            
            /// 判断是否是最后一个 item
            if i == count - 1 {
                /// 最后一个 完成 所有的 item 展示
                delegate?.cardView(self, didEndDisplaying: item, forAt: visibleMaxIndex - i)
            }
            
            if animate {
                updateConstraints(for: item, tranform: transform)
            } else {
                item.transform = transform
            }
        }
    }
    
    /// item transform 变换
    private func updateConstraints(for item: WQCardViewBaseItem, tranform: CGAffineTransform) {
        UIView.animate(withDuration: WQDefaluteAnimateDuration) {
            item.transform = tranform
        }
    }
}

//MARK: - 卡片的代理方法
extension WQCardView: WQCardViewItemDelegate {
    
    /// item 卡片将要从父视图移除
    func cardViewItemWillRemoveFromSuperView<Operation: WQCardViewItemOperationable>(_ item: WQCardViewItem<Operation>) {
        print("==================")
    }

    /// item 卡片从父视图移除的代理
    func cardViewItemDidRemoveFromSuperView<Operation>(_ item: WQCardViewItem<Operation>) where Operation : WQCardViewItemOperationable {
        moveCount += 1
        reusableItemsDic[item.identifier]?.append(item as! WQCardViewBaseItem)
        /// 代理 移除了当前item
        delegate?.cardView(self, didRemove: item as! WQCardViewBaseItem, forAt: currentTopItemIndex())
        
        let itemCount = dataSource.numberOfItems(in: self)
        /// 处理移除后的卡片是否是最后一张 ）
        guard visibleItems.count > 0 else {
            moveCount = 0
            delegate?.cardView(self, didRemoveLast: item as! WQCardViewBaseItem)
            return
        }
        /// 当前还有数据继续 取 item
        if visibleMaxIndex < itemCount - 1 {
            createItemforCardView(in: visibleMaxIndex + 1)
        }
        /// 动画更新布局
        updateLayoutVisibleItem(with: true)
    }
    
    /// item 卡片在父视图移动到某个位置
    func cardViewItemDidMoveOnSuperView<Operation>(_ item: WQCardViewItem<Operation>, toPoint: CGPoint) where Operation : WQCardViewItemOperationable {
        
    }
}

//MARK: - WQCardViewDelegate 相关内容
extension WQCardView {
    /// 卡片完成移除
    func cardView(didRemove item: WQCardViewBaseItem) {
        moveCount += 1
        
        // item 被移除的时，重新刷新视图
//        delegate?.cardView(self, didRemove: item, forAt: currentIndex)
    }
}


