//
//  MessageView.swift
//  HeatChat
//
//  Created by BAM on 2017-11-27.
//  Copyright © 2017 BAM. All rights reserved.
//

import UIKit

class MessageView: UITextView {

    var keyTag : String!
    var message : Chat!
    
    init(frame: CGRect, textContainer: NSTextContainer?, tag : String, message : Chat){
        super.init(frame: frame, textContainer: textContainer)
        self.keyTag = tag
        self.message = message
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(){
        
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
