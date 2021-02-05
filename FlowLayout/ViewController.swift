//
//  ViewController.swift
//  FlowLayout
//
//  Created by 王欣 on 2021/2/5.
//

import UIKit
import MJRefresh

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var dataCount = 3
    var otherDataCount = 5
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mj = MJRefreshGifHeader.init {
            [weak self] in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self?.dataCount = 10
                self?.collectionView.reloadData()
                self?.collectionView.mj_header?.endRefreshing()
            }
        }
        self.collectionView.mj_header = mj
        collectionView.register(FlowlayoutCell.self, forCellWithReuseIdentifier: "cell")
        let nib = UINib.init(nibName: "FlowCollectionReusableView", bundle: nil)
        collectionView.register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FlowCollectionReusableView")
        let footernib = UINib.init(nibName: "CollectionReusableFooterView", bundle: nil)
        collectionView.register(footernib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "CollectionReusableFooterView")
        
        rightBar()
        // Do any additional setup after loading the view.
    }
    
    
    func rightBar()  {
        let bar = UIBarButtonItem.init(title: "滑动", style: .done, target: self, action: #selector(scrollAction))
        navigationItem.rightBarButtonItem = bar
    }
    
    @objc func scrollAction(){
        if let layout = collectionView.collectionViewLayout as? FlowLayout{
            if dataCount > 4 {
                layout.scrolllToIndex(index: IndexPath.init(row: 4, section: 1))
            }
        }
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        if dataCount == 0 {
            return
        }
        let index = dataCount - 1
        dataCount = index
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
        collectionView.performBatchUpdates {
            self.collectionView.deleteItems(at: [IndexPath.init(item: index, section: 1)])
        } completion: { (_) in
            
        }
    }
    
    @IBAction func addAction(_ sender: Any) {
        self.dataCount += 1
        self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
        self.collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: [IndexPath.init(item: self.dataCount - 1, section: 1)])
            
        } completion: { (_) in
            
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension ViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateWaterFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacing section: Int) -> CGFloat {
        return 10
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, colum section: Int)
    -> Int {
        if section == 0 {
            return 1
        }
        if section == 1 {
            return 2
        }
        return 3
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.init(width: collectionView.bounds.width, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        .init(width: collectionView.bounds.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sectionInsetForItems section: Int) -> UIEdgeInsets{
        
        return UIEdgeInsets.init(top: 20, left: 10, bottom: 20, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view =   collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FlowCollectionReusableView", for: indexPath)
            return view
        }else{
            let view =   collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "CollectionReusableFooterView", for: indexPath)
            return view
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, itemWidth:CGFloat ,caculateHeight indexPath: IndexPath) -> CGFloat{
        
        return CGFloat(indexPath.row * 40 + 170)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return dataCount
        }
        return self.otherDataCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FlowlayoutCell
        
        cell.textLab.text = "\(indexPath)"
        return cell
    }
}
