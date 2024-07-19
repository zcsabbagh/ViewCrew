//
//  FontExtensions.swft.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/19/24.
//

import Foundation
import SwiftUI

extension Font {
    static func roboto(_ size: CGFloat) -> Font {
        return Font.custom("Roboto-Regular", size: size)
    }
    
    static func robotoBold(_ size: CGFloat) -> Font {
        return Font.custom("Roboto-Bold", size: size)
    }
}
