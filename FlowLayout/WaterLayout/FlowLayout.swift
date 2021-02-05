//
//  FlowLayout.swift
//  SwiftTest
//
//  Created by 王欣 on 2021/1/20.
//  Copyright © 2021 王欣. All rights reserved.
//

import UIKit



private class UsedCarSectionInfo{
    
    typealias LayoutAttribute = UICollectionViewLayoutAttributes
    private var linesLastValue:[Int:CGRect] = [:]
    var headerAttribute:LayoutAttribute?
    var itemAttribute:[LayoutAttribute] = []
    var footerAttribute:LayoutAttribute?
    var decorAttribute:LayoutAttribute?
    
    let colum:Int
    let origin:CGPoint
    let itemWidth:CGFloat
    let minimumInteritemSpacing:CGFloat
    let celledgeInset:UIEdgeInsets
        
    init(colum:Int,itemWidth:CGFloat,minimumInteritemSpacing:CGFloat,edgeInset:UIEdgeInsets) {
        self.colum = colum
        self.itemWidth = itemWidth
        self.celledgeInset = edgeInset
        self.origin = .init(x: edgeInset.left, y: edgeInset.top)
        self.minimumInteritemSpacing = minimumInteritemSpacing
    }
    
    ///获取当前section的y轴最大值
    func maxY() -> CGFloat {
        if let footer = footerAttribute{
            return footer.frame.maxY
        }
        if let _ = itemAttribute.last{
            return findExtremeValue(true).1.maxY + celledgeInset.bottom
        }
        if let header = headerAttribute{
            return header.frame.maxY
        }
        return celledgeInset.top
    }
    
    ///获取当前section的y轴最大值
    func minY() -> CGFloat {
        if let header = headerAttribute{
            return header.frame.minY
        }
        if let firstItem = itemAttribute.first{
            return firstItem.frame.minY
        }
        if let footer = headerAttribute{
            return footer.frame.minY
        }
        return celledgeInset.top
    }
    
    ///更新排序
    func updateRect(colum:Int,value:CGRect)  {
        linesLastValue[colum] = value
    }
    
    func initLinesLastValue(_ rect:CGRect)  {
        linesLastValue[0] = rect
        for index in 1 ..< Int(colum) {
            linesLastValue[index] = CGRect(x: rect.minX + (minimumInteritemSpacing + rect.width) * CGFloat(index), y: rect.minY + 0.1 * CGFloat(index) , width: rect.width, height: -(0.1 * CGFloat(index)))
        }
    }
    
    
    /// 对比每列的最后一个元素,获取最大值或最小值
    func findExtremeValue(_ max: Bool) -> (Int, CGRect) {
        if let value = linesLastValue.compactMap({ ($0, $1) }).sorted(by: {
            if max == false {
                return $0.1.maxY > $1.1.maxY
            } else {
                return $0.1.maxY < $1.1.maxY
            }
        }).last {
            return value
        }
        return (0, CGRect(origin: origin, size: .zero))
    }
}



@objc public protocol UICollectionViewDelegateWaterFlowLayout: UICollectionViewDelegateFlowLayout {
    /**
     返回当前section中的列数
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, colum section: Int) -> Int
    /**
     返回当前section中cell的行间距
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacing section: Int) -> CGFloat
    
    /**
     返回当前section中cell的内间距
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sectionInsetForItems section: Int) -> UIEdgeInsets
    /**
     返回当前indexpath的高度,可以根据宽度来计算
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, itemWidth: CGFloat, caculateHeight indexPath: IndexPath) -> CGFloat
}


@objc public class FlowLayout: UICollectionViewFlowLayout {
    // 插入的条目 --- 操作数组 ---
    
    private lazy var insertingIndexPaths = [IndexPath]()
    // 刷新的条目
    private lazy var reloadIndexPaths    = [IndexPath]()
    // 删除的条目
    private lazy var deletingIndexPaths  = [IndexPath]()
    // --- 操作数组 ---
    
    // 分区的内容信息,用来做布局处理
    private lazy var sectionInfos: [Int: UsedCarSectionInfo] = [:]
    
    //    private lazy var animator: UIDynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
    
    
    public enum BounceStyle {
        case subtle
        case regular
        case prominent
        
        var damping: CGFloat {
            switch self {
            case .subtle: return 0.8
            case .regular: return 0.7
            case .prominent: return 0.5
            }
        }
        
        var frequency: CGFloat {
            switch self {
            case .subtle: return 2
            case .regular: return 1.5
            case .prominent: return 1
            }
        }
    }
    
    private var damping: CGFloat = BounceStyle.regular.damping
    private var frequency: CGFloat = BounceStyle.regular.frequency
    
    // updateItem doesn't take into account size changes
    // so we track visible size changes and re-prepare
    // behaviors on change
    private var visibleItemsSizeCache: [IndexPath:CGSize] = [:]
    private var visibleIndexPaths: Set<IndexPath> = Set()
    
    /**
     获取每个item的宽度
     */
    func getItemWidth(for section: Int) -> CGFloat {
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateWaterFlowLayout {
            let edge = delegate.collectionView(collectionView, layout: self, sectionInsetForItems: section)
            let colum = delegate.collectionView(collectionView, layout: self, colum: section)
            var totalLineSpace: CGFloat = 0
            if colum > 1 {
                totalLineSpace = minimumInteritemSpacing * CGFloat(colum - 1)
            }
            let width = (collectionView.bounds.size.width - edge.left - edge.right - totalLineSpace) / CGFloat(colum)
            return width
        }
        return UIScreen.main.bounds.width
    }
    
    /// 获取当前各分区y轴最大的值
    private func maxY() -> CGFloat {
        if let sectionInfo = sectionInfos.values.sorted(by: { $0.maxY() > $1.maxY() }).first {
            return sectionInfo.maxY()
        }
        return 0
    }
}

/// 滑动代理事件
extension FlowLayout {
    @objc public func scrollToHeader(with section: Int) {
        let indexPath = IndexPath(row: 0, section: section)
        scrollWith(indexPath, isHeader: true, isFooter: false)
    }
    
    @objc public func scrollToFooter(with section: Int) {
        let indexPath = IndexPath(row: 0, section: section)
        scrollWith(indexPath, isHeader: false, isFooter: true)
    }
    
    @objc public func scrolllToIndex(index: IndexPath) {
        scrollWith(index, isHeader: false, isFooter: false)
    }
    
    private func scrollWith(_ indexPath: IndexPath, isHeader: Bool, isFooter: Bool) {
        let sectionInfo = sectionInfos[indexPath.section]
        if isHeader, let att = sectionInfo?.headerAttribute {
            collectionView?.setContentOffset(CGPoint(x: 0, y: att.frame.origin.y), animated: true)
            return
        }
        if isHeader, let att = sectionInfo?.footerAttribute {
            collectionView?.setContentOffset(CGPoint(x: 0, y: att.frame.origin.y), animated: true)
            return
        }
        if let att = sectionInfo?.itemAttribute[indexPath.row] {
            collectionView?.setContentOffset(CGPoint(x: 0, y: att.frame.origin.y), animated: true)
        }
    }
}

/**
 重写布局相关的方法
 */
extension FlowLayout {
    typealias LayoutAttribute = UICollectionViewLayoutAttributes
    
    /**
     当集合视图第一次显示其内容时，以及当由于视图的更改而显式或隐式地使布局失效时，就会发生布局更新。在每次布局更新期间，集合视图首先调用这个方法，让布局对象有机会为即将到来的布局操作做准备。
     这个方法的默认实现不做任何事情。子类可以覆盖它，并使用它来设置数据结构或执行后续执行布局所需的任何初始计算。
     */
    override public func prepare() {
        
        print(#function)
        super.prepare()
        sectionInfos.removeAll()
        //        animator.removeAllBehaviors()
        self.register(UCCateDecorationView.self, forDecorationViewOfKind: "UCCateDecorationView")
        guard let collectionView = self.collectionView, let delegate = collectionView.dataSource as? UICollectionViewDelegateWaterFlowLayout else {
            return
        }
        let sectionNum = collectionView.numberOfSections
        /// 获取到分区
        for sectionIndex in 0 ..< sectionNum {
            let section = IndexPath(row: 0, section: sectionIndex)
            let cellEdge = delegate.collectionView(collectionView, layout: self, sectionInsetForItems: sectionIndex)
            ///获取section的列间距
            let lineSpace = delegate.collectionView(collectionView, layout: self, minimumLineSpacing: sectionIndex)
            /// 查看布局中存在几列
            let colum = delegate.collectionView(collectionView, layout: self, colum: sectionIndex)
            let sectionInfo = UsedCarSectionInfo(colum: colum, itemWidth: getItemWidth(for: sectionIndex), minimumInteritemSpacing: minimumInteritemSpacing, edgeInset: cellEdge)
            
            sectionInfos[sectionIndex] = sectionInfo
            /// 处理header数据
            if let att = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: section)?.copy() as? LayoutAttribute {
                var maxY: CGFloat = 0
                if section.section > 0, let preInfo = sectionInfos[section.section - 1] { maxY = preInfo.maxY() }
                var frame = att.frame
                frame.origin = CGPoint(x: frame.origin.x, y: maxY)
                att.frame = frame
                sectionInfo.headerAttribute = att
                //                addItem(att, in: collectionView)
            }
            /// 处理cell数据
            let cellNumForSection = collectionView.numberOfItems(inSection: sectionIndex)
            for index in 0 ..< cellNumForSection {
                let indexPath = IndexPath(row: index, section: sectionIndex)
                if let att = layoutAttributesForItem(at: indexPath)?.copy() as? LayoutAttribute {
                    var frame = att.frame
                    let height = delegate.collectionView(collectionView, layout: self, itemWidth: sectionInfo.itemWidth, caculateHeight: indexPath)
                    frame.size = .init(width: sectionInfo.itemWidth, height: height)
                    var newOrigin = CGPoint.zero
                    if indexPath.row == 0 {
                        newOrigin = .init(x: sectionInfo.origin.x, y: maxY() + sectionInfo.celledgeInset.top)
                        frame.origin = newOrigin
                        sectionInfo.initLinesLastValue(frame)
                    } else {
                        ///查找当前section中哪列最短
                        let tuple = sectionInfo.findExtremeValue(false)
                        let caluteMinimumLineSpacing = tuple.1.size.height < 0 ? 0 : lineSpace
                        newOrigin = CGPoint(x: tuple.1.minX, y: tuple.1.maxY + caluteMinimumLineSpacing)
                        frame.origin = newOrigin
                        sectionInfo.updateRect(colum: tuple.0, value: frame)
                    }
                    att.frame = frame
                    sectionInfo.itemAttribute.append(att)
                    //                    addItem(att, in: collectionView)
                }
            }
            // 处理footer数据
            if let att = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: section)?.copy() as? LayoutAttribute {
                var maxY: CGFloat = 0
                maxY = sectionInfo.maxY()
                var frame = att.frame
                frame.origin = CGPoint(x: frame.origin.x, y: maxY)
                att.frame = frame
                sectionInfo.footerAttribute = att
                //                addItem(att, in: collectionView)
            }
            if section.section == 0{
                if let att = layoutAttributesForDecorationView(ofKind: "UCCateDecorationView", at: section)?.copy() as? LayoutAttribute{
                    let offsetX:CGFloat = 400
                    let newOrigin = CGPoint.init(x: collectionView.bounds.origin.x, y: sectionInfo.minY() - offsetX)
                    let newSize = CGSize.init(width: collectionView.bounds.width, height: sectionInfo.maxY() - sectionInfo.minY() + offsetX)
                    att.frame = CGRect.init(origin: newOrigin, size: newSize)
                    sectionInfo.decorAttribute = att
                    //                addItem(att, in: collectionView)
                }
            }
        }
    }
    
    /**
     private func addItem(_ item: UICollectionViewLayoutAttributes, in view: UICollectionView) {
     let behavior = UIAttachmentBehavior(item: item, attachedToAnchor: floor(item.center))
     animator.addBehavior(behavior, damping, frequency)
     visibleIndexPaths.insert(item.indexPath)
     visibleItemsSizeCache[item.indexPath] = item.bounds.size
     }
     */
    
    
    override public var collectionViewContentSize: CGSize {
        if let collectionView = self.collectionView {
            let contentSize = CGSize(width: collectionView.bounds.width, height: max(maxY(), collectionView.bounds.height))
            return contentSize
        }
        return .zero
    }
    
    /// 没有直接返回super调用,是因为在增加,删除,刷新等操作中,会再次执行该方法,布局计算是以当前的item的下一个做变化操作,和要求动画不符
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let sectionInfo = sectionInfos[indexPath.section], sectionInfo.itemAttribute.count > indexPath.row {
            return sectionInfo.itemAttribute[indexPath.row]
        }
        return super.layoutAttributesForItem(at: indexPath)
    }
    
    /// 没有直接返回super调用,是因为在增加,删除,刷新等操作中,会再次执行该方法,布局计算是以当前的item的下一个做变化操作,和要求动画不符
    override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let sectionInfo = sectionInfos[indexPath.section] {
            if elementKind == UICollectionView.elementKindSectionHeader, let att = sectionInfo.headerAttribute {
                return att
            }
            if elementKind == UICollectionView.elementKindSectionFooter, let att = sectionInfo.footerAttribute {
                return att
            }
        }
        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
    
    public override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let att = UICollectionViewLayoutAttributes.init(forDecorationViewOfKind: elementKind, with: indexPath)
        att.zIndex = -1
        
        return att
    }
    
    /// 返回当前rect中包含的布局信息
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return sectionInfos.values.flatMap { (info) -> [LayoutAttribute] in
            var arr = [UICollectionViewLayoutAttributes]()
            if let header = info.headerAttribute, header.frame.intersects(rect) {
                arr.append(header)
            }
            arr.append(contentsOf: info.itemAttribute.filter { $0.frame.intersects(rect) })
            if let footer = info.footerAttribute, footer.frame.intersects(rect) {
                arr.append(footer)
            }
            if let att = info.decorAttribute,att.frame.intersects(rect){
                arr.append(att)
            }
            return arr
        }
    }
    
}

/// item增加删除相关的方法
extension FlowLayout {
    
    /// 监听视图内容item变化操作
    override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        for update in updateItems {
            if let indexPath = update.indexPathAfterUpdate,update.updateAction == .insert {
                insertingIndexPaths.append(indexPath)
            }
            if let indexPath = update.indexPathAfterUpdate, update.updateAction == .reload {
                reloadIndexPaths.append(indexPath)
            }
            if let indexPath = update.indexPathBeforeUpdate, update.updateAction == .delete {
                deletingIndexPaths.append(indexPath)
            }
        }
    }
    
    /// item将要显示的时候调用,处理相关动画
    override public func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        if insertingIndexPaths.contains(itemIndexPath), let copyModel = attributes?.copy() as? LayoutAttribute {
            if let sectionInfo = sectionInfos[itemIndexPath.section], sectionInfo.itemAttribute.count > itemIndexPath.row {
                let att = sectionInfo.itemAttribute[itemIndexPath.row]
                copyModel.alpha = 0
                copyModel.frame = att.frame
                copyModel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }
            return copyModel
        }
        if reloadIndexPaths.contains(itemIndexPath), let copyModel = attributes?.copy() as? LayoutAttribute {
            if let sectionInfo = sectionInfos[itemIndexPath.section], sectionInfo.itemAttribute.count > itemIndexPath.row {
                let att = sectionInfo.itemAttribute[itemIndexPath.row]
                copyModel.alpha = 0
                copyModel.frame = att.frame
            }
            return copyModel
        }
        return attributes
    }
    
    /// 视图变化完成调用
    override public func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        insertingIndexPaths.removeAll()
        deletingIndexPaths.removeAll()
        reloadIndexPaths.removeAll()
    }
    
    /// 删除item会执行此代理方法,处理删除相关的动画
    override public func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        if deletingIndexPaths.contains(itemIndexPath), let copyModel = attributes?.copy() as? LayoutAttribute {
            copyModel.alpha = 0.0
            copyModel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            return copyModel
        }
        return attributes
    }
    /**
     open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
     guard let view = collectionView else { return false }
     
     animator.behaviors.forEach {
     guard let behavior = $0 as? UIAttachmentBehavior,
     let item = behavior.items.first else {
     return
     }
     update(behavior: behavior, and: item, in: view, for: newBounds)
     animator.updateItem(usingCurrentState: item)
     }
     return false // animator will automatically notify FlowLayout to invalidate
     }
     */
    
    
    private func update(behavior: UIAttachmentBehavior, and item: UIDynamicItem, in view: UICollectionView, for bounds: CGRect) {
        let delta = CGVector(dx: bounds.origin.x - view.bounds.origin.x, dy: bounds.origin.y - view.bounds.origin.y)
        let resistance = CGVector(dx: abs(view.panGestureRecognizer.location(in: view).x - behavior.anchorPoint.x) / 1000, dy: abs(view.panGestureRecognizer.location(in: view).y - behavior.anchorPoint.y) / 1000)
        
        switch scrollDirection {
        case .horizontal: item.center.x += delta.dx < 0 ? max(delta.dx, delta.dx * resistance.dx) : min(delta.dx, delta.dx * resistance.dx)
        case .vertical: item.center.y += delta.dy < 0 ? max(delta.dy, delta.dy * resistance.dy) : min(delta.dy, delta.dy * resistance.dy)
        @unknown default:
            item.center.y += delta.dy < 0 ? max(delta.dy, delta.dy * resistance.dy) : min(delta.dy, delta.dy * resistance.dy)
        }
        
        item.center = floor(item.center)
    }
}


extension UIDynamicAnimator {
    open func addBehavior(_ behavior: UIAttachmentBehavior, _ damping: CGFloat, _ frequency: CGFloat) {
        behavior.damping = damping
        behavior.frequency = frequency
        addBehavior(behavior)
    }
}



fileprivate func floor(_ point: CGPoint) -> CGPoint {
    CGPoint(x: floor(point.x), y: floor(point.y))
}
