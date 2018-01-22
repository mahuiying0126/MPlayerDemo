//
//  MCommonTool.swift
//  MAVPlayerDmeo
//
//  Created by yizhilu on 2017/7/12.
//  Copyright © 2017年 Magic. All rights reserved.
//

import Foundation
import UIKit
public let Screen_height = UIScreen.main.bounds.size.height
public let Screen_width = UIScreen.main.bounds.size.width

public let Ratio_height = UIScreen.main.bounds.size.height / 667.0
public let Ratio_width = UIScreen.main.bounds.size.width / 375.0

public func FONT(_ int:CGFloat) ->UIFont {
    return UIFont .systemFont(ofSize: int)
}

public func MIMAGE(_ imageName:String)->UIImage{
    
    return UIImage.init(named: imageName)!
}

public func UIColorFromRGB(_ rgbValue :NSInteger) ->UIColor{
    
    return UIColor (red: ((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0, green: ((CGFloat)((rgbValue & 0xFF00) >> 8))/255.0, blue: ((CGFloat)(rgbValue & 0xFF))/255.0, alpha: 1.0)
}

public func ColorFromRGB(_ R:CGFloat,_ G:CGFloat,_ B:CGFloat ,_ A:CGFloat)->UIColor{
    
    return UIColor (red: R / 255.0 , green: G/255.0, blue: B/255.0, alpha: A)
}

public let Whit = UIColor.white
