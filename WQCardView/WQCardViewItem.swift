//
//  WQCardViewItem.swift
//  WQCardView
//
//  Created by 王伟奇 on 2019/4/25.
//  Copyright © 2019 王伟奇. All rights reserved.
//

import UIKit

/// item 的代理方法
protocol WQCardViewItemDelegate: class {
    /// item 卡片将要从父视图移除
    func cardViewItemWillRemoveFromSuperView<Operation: WQCardViewItemOperationable>(_ item: WQCardViewItem<Operation>)
    
    /// item 卡片从父视图移除的代理
    func cardViewItemDidRemoveFromSuperView<Operation: WQCardViewItemOperationable>(_ item: WQCardViewItem<Operation>)
    
    /// item 卡片在父视图移动到某个位置
    func cardViewItemDidMoveOnSuperView<Operation: WQCardViewItemOperationable>(_ item: WQCardViewItem<Operation>, toPoint: CGPoint) 
}

/// 卡片 item 的操作协议 (移动， 移除， 复位)
public protocol WQCardViewItemOperationable: class {
    
    /// 手势开始的时候
    func panGestrueStateBegan(item: UIView, pan: UIPanGestureRecognizer)
    
    /// 手势改变时候的操作
    func panGestureStateChanged(item: UIView, pan: UIPanGestureRecognizer)
    
    /// item 归位操作
    func resoreItemLocation(item: UIView, pan: UIPanGestureRecognizer)
    
    /// 拖手饰操作完毕处理事件
    func panGestureStateEnded(item: UIView, pan: UIPanGestureRecognizer, completion:@escaping VoidBlock)
    
    /// 扫（动作方向） 操作移除 item
    func swipeRemoveFromSuperview(item: UIView, by location: WQCardCellSwipeDirection, completion:@escaping VoidBlock)
    
    init()
}

/// 基础的手机操作交互
public class WQCardViewItemBaseOperation: WQCardViewItemOperationable {
    /// 当前位置
    var currentPoint = CGPoint()
    /// 移除的 边界值
    let maxRemoveDistance: CGFloat = UIScreen.width / 4
    /// 卡片旋转的最大角度
    let maxAngle: CGFloat = 30
    
    public required init() {}
    
    public func panGestrueStateBegan(item: UIView, pan: UIPanGestureRecognizer) {
        currentPoint = CGPoint()
    }
    
    public func panGestureStateChanged(item: UIView, pan: UIPanGestureRecognizer) {
        /// 移动到的点位置
        let moveToPoint = pan.translation(in: pan.view)
        currentPoint = currentPoint + moveToPoint
        /// 移动距离 占 移除最大边界值的百分之多少。（横向 x 的距离）
        var moveRatio = currentPoint.x / maxRemoveDistance
        moveRatio = moveRatio > 0 ? min(moveRatio, 1) : max(-1, moveRatio)
        let angle = maxAngle.degreeRadians * moveRatio
        let transRotation = CGAffineTransform.init(rotationAngle: angle)
        item.transform = transRotation.translatedBy(x: currentPoint.x, y: currentPoint.y)
        pan.setTranslation(CGPoint.zero, in: pan.view)
    }
    
    public func resoreItemLocation(item: UIView, pan: UIPanGestureRecognizer) {
        UIView.animate(withDuration: 0.5, delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
                        item.transform = CGAffineTransform.identity
        }) { (_) in
            
        }
    }
    
    public func panGestureStateEnded(item: UIView, pan: UIPanGestureRecognizer, completion:@escaping VoidBlock) {
        if currentPoint.x > maxRemoveDistance || currentPoint.x < -maxRemoveDistance {
            swipeRemoveFromSuperview(item: item, by: currentPoint.x > maxRemoveDistance ? .right : .left, completion: completion)
        } else {  /// 滑动移除条件不满足归位
            resoreItemLocation(item: item, pan: pan)
        }
    }
    
    public func swipeRemoveFromSuperview(item: UIView, by location: WQCardCellSwipeDirection, completion:@escaping VoidBlock) {
        guard let snapshotView = item.snapshotView(afterScreenUpdates: false) else { return }
        snapshotView.frame = item.frame
        snapshotView.transform = item.transform
        item.superview?.addSubview(snapshotView)
        cardViewItemDidRemoveFromSuperView(item)
        let endCenterX = UIScreen.width / 2 +
            CGFloat(location.hashValue) * (item.frame.size.width * 1.5)
        UIView.animate(withDuration: 0.25, animations: {
            var center = snapshotView.center
            center.x = endCenterX
            snapshotView.center = center
        }) { (_) in
            snapshotView.removeFromSuperview()
            completion()
        }
    }
    
    private func cardViewItemDidRemoveFromSuperView(_ item: UIView) {
        item.transform = CGAffineTransform.identity
        item.removeFromSuperview()
    }
}


/// 卡片
public class WQCardViewItem<Operation: WQCardViewItemOperationable>: UIView {
    
    public var index: Int?
    weak var delegate: WQCardViewItemDelegate?
    /// 标识符
    var identifier: String!
    /// 移除的 边界值
    var maxRemoveDistance: CGFloat?
    var maxAngle: CGFloat?
    /// 手势操作的动作执行
    private lazy var panOperation = Operation()
    
    private var currentPoint: CGPoint?
    
    /// 便利构造函数
    required convenience init(reuseIdentifier: String?) {
        self.init()
//        isUserInteractionEnabled = true
        identifier = reuseIdentifier
        setupView()
    }
    
    /// 从视图中移除
    func removeFromSuperView(by direction: WQCardCellSwipeDirection) {
        swipeRemoveFromSuperview(by: direction)
    }
    
    private func setupView() {
        
        /// 添加拖手饰
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecogizer(sender:)))
        addGestureRecognizer(panGesture)
    }
    
    /// 拖手势响应
    @objc private func panGestureRecogizer(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began: /// 手饰开始
            panOperation.panGestrueStateBegan(item: self, pan: sender)
        case .changed:   ///pan拖动改变
            panOperation.panGestureStateChanged(item: self, pan: sender)
        case .ended:     /// 手势完成
            panOperation.panGestureStateEnded(item: self, pan: sender) {
                self.cardViewItemDidRemoveFromSuperView(self)
            }
        case .cancelled, .failed:    ///手势失败 或者取消
            panOperation.resoreItemLocation(item: self, pan: sender)
        default:
            break
        }
    }
    
    /// item 移除操作
//    func removeItemFromSuperView() {
//        
//    }
    
    /// 扫（动作方向） 操作移除 item
    func swipeRemoveFromSuperview(by location: WQCardCellSwipeDirection) {
        panOperation.swipeRemoveFromSuperview(item: self, by: location) {
            self.cardViewItemDidRemoveFromSuperView(self)
        }
    }
    
    /// 卡片视图从父视图移除
    private func cardViewItemDidRemoveFromSuperView(_ item: UIView) {
        item.transform = CGAffineTransform.identity
        delegate?.cardViewItemWillRemoveFromSuperView(self)
        removeFromSuperview()
        delegate?.cardViewItemDidRemoveFromSuperView(self)
    }
}

/// 基础的卡片
public class WQCardViewBaseItem: WQCardViewItem<WQCardViewItemBaseOperation> {
    
}

