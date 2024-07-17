//  HapticFeedback.swift
//  Roll
//
//  Created by Christen Xie on 12/19/23.
//

import Foundation
import SwiftUI

final class HapticFeedbackGenerator {

    static let shared = HapticFeedbackGenerator()
    
    private init() {}
    
    private var generator: UIImpactFeedbackGenerator?
    
    func generate(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        generator = UIImpactFeedbackGenerator(style: style)
        generator?.impactOccurred()
    }

    func generateHapticLight() {
        generate(style: .light)
    }

    func generateHapticMedium() {
        generate(style: .medium)
    }

    func generateHapticHeavy() {
        generate(style: .heavy)
    }

}
