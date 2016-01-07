//
//  MCScanView.swift
//  imooc
//
//  Created by GJ on 15/12/21.
//  Copyright © 2015年 imooc. All rights reserved.
//

import UIKit

class MCScanView: UIView {

    var topMargin: CGFloat {
        return 100
    }
    
    var scanFrame: CGRect {
        let screenW = UIScreen.mainScreen().bounds.size.width
        let wh = CGFloat(210)
        let x = CGFloat(screenW - wh) * 0.5
        return CGRect(x: x, y: 100, width: wh, height: wh)
    }
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext();
        
        UIColor(white: 0, alpha: 0.6).setFill()
        let screenPath = CGPathCreateMutable();
        CGPathAddRect(screenPath, nil, self.bounds);
        
        let scanPath = CGPathCreateMutable();
        CGPathAddRect(scanPath, nil, scanFrame);
        
        let path = CGPathCreateMutable();
        CGPathAddPath(path, nil, screenPath);
        CGPathAddPath(path, nil, scanPath);
        
        CGContextAddPath(ctx, path);
        CGContextDrawPath(ctx, .EOFill);
    }
}
