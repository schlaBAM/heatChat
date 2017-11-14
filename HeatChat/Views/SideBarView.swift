//
//  SideBarView.swift
//  HeatChat
//
//  Created by BAM on 2017-11-13.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation
import UIKit

protocol SideBarDelegate {
    func open(sideBar : SideBarView)
    func close(sideBar : SideBarView)
}

class SideBarView : UITableView {
    
    var isOpen = false
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        
        setupUI()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(){
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = 5
        self.separatorStyle = .none
        open(sideBar: self)
    }
    
    func open(sideBar : SideBarView){
        
    }
    
    func animateSideBar(_ view: UIView) {
        
        if self.center.x < 0 {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                self.center.x += view.bounds.width * 0.5
            })
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                self.center.x -= view.bounds.width * 0.5
            })
        }
    }
}
