//
//  FlowlayoutCell.swift
//  SwiftTest
//
//  Created by 王欣 on 2021/1/20.
//  Copyright © 2021 王欣. All rights reserved.
//

import UIKit
import SnapKit
class FlowlayoutCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        self.backgroundColor = UIColor.brown
        contentView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        contentView.addSubview(imgView)
        contentView.addSubview(textLab)
        imgView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }
        textLab.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(15)
            make.centerX.equalToSuperview()
            
        }
    }
    
    lazy var textLab: UILabel = {
        let lab = UILabel.init()
        lab.textColor = .black
        lab.numberOfLines = 0
        lab.font = .boldSystemFont(ofSize: 16)
        return lab
    }()
    
    lazy var imgView: UIImageView = {
        let image = UIImageView.init(image: UIImage.init(named: "image"))
        image.contentMode = .scaleAspectFill
        return image
    }()
}
