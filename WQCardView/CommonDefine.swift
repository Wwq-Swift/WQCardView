//
//  CommonDefine.swift
//  WQCardView
//
//  Created by 王伟奇 on 2019/4/22.
//  Copyright © 2019 王伟奇. All rights reserved.
//

import UIKit

public typealias VoidBlock = () -> Void

let WQDefaluteAnimateDuration: TimeInterval = 0.25

extension UIScreen {
    public static var width: CGFloat {
        get {
            return UIScreen.main.bounds.width
        }
    }
    public static var height: CGFloat {
        get {
            return UIScreen.main.bounds.height
        }
    }
}


extension CGPoint {
    static func +(_ left: CGPoint, _ right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}

extension CGFloat {
    var degreeRadians: CGFloat {
        get {
            return self / (180 * CGFloat.pi)
        }
    }
}
