//
//  MyDecorationView.swift
//  SwiftTest
//
//  Created by 王欣 on 2021/1/28.
//  Copyright © 2021 王欣. All rights reserved.
//

import UIKit

class UCCateDecorationView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
