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
    
    init(frame: CGRect, textContainer: NSTextContainer?, tag : String){
        super.init(frame: frame, textContainer: textContainer)
        self.keyTag = tag
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
