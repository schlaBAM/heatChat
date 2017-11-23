//
//  NoMessagesView.swift
//  HeatChat
//
//  Created by BAM on 2017-11-22.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation
import UIKit

class NoMessagesView : UIView{
    
    let farLabel = "No messages yet!"
    let closeLabel = "No messages yet. Start the conversation!"
    var textLabel = UILabel()
    
    init(frame: CGRect, isClose : Bool){
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        textLabel.frame = CGRect(x: self.bounds.width * 0.1, y: self.bounds.height * 0.5, width: self.bounds.width * 0.8, height: self.bounds.height * 0.125)
        textLabel.font = UIFont.systemFont(ofSize: 15)
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.textColor = .black
        textLabel.textAlignment = .center
        
        if isClose {
            textLabel.text = self.closeLabel
        } else {
            textLabel.text = self.farLabel
        }
        
        self.addSubview(textLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
