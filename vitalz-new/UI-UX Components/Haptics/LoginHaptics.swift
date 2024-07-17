//
//  LoginHaptics.swift
//  Roll
//
//  Created by Zane Sabbagh on 12/14/23.
//

import Foundation
import UIKit
import CoreHaptics

class LoginHaptics {
    public var engine: CHHapticEngine?

    init() {
        prepareHaptics()
    }

    public func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    // ... Your existing complexSuccess() function ...

    public func hapticEffectOne() {
        // A gentle, increasing haptic pattern
        print("Playing haptic effect 1")
        createHapticPattern(startIntensity: 0.1, endIntensity: 0.0, startSharpness: 0.1, endSharpness: 0.9, duration: 1.0)
    }

    public func hapticEffectTwo() {
        print("Playing haptic effect 2")
        // A slightly stronger and longer pattern
        createHapticPattern(startIntensity: 0.3, endIntensity: 0.5, startSharpness: 0.3, endSharpness: 0.5, duration: 1.5)
    }

    public func hapticEffectThree() {
        print("Playing haptic effect 3")
        // A medium strength pattern with more noticeable feedback
        createHapticPattern(startIntensity: 0.5, endIntensity: 0.7, startSharpness: 0.5, endSharpness: 0.7, duration: 2.0)
    }

    public func hapticEffectFour() {
        print("Playing haptic effect 4")
        // A stronger, more pronounced haptic pattern
        createHapticPattern(startIntensity: 0.7, endIntensity: 0.9, startSharpness: 0.7, endSharpness: 0.9, duration: 2.5)
    }

    public func hapticEffectFive() {
        print("Playing haptic effect 5")
        // The strongest and longest haptic pattern
        createHapticPattern(startIntensity: 0.9, endIntensity: 1.0, startSharpness: 0.9, endSharpness: 1.0, duration: 3.0)
    }

    public func createHapticPattern(startIntensity: Float, endIntensity: Float, startSharpness: Float, endSharpness: Float, duration: TimeInterval) {
        var events = [CHHapticEvent]()

        // Create a sequence of haptic events that increases in intensity and sharpness
        for i in stride(from: 0, to: duration, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: startIntensity + Float(i/duration) * (endIntensity - startIntensity))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: startSharpness + Float(i/duration) * (endSharpness - startSharpness))
            let event = CHHapticEvent(
                eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern \(error.localizedDescription)")
        }
    }
    
    func triggerHapticFeedbackHeavy() {
            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedbackgenerator.impactOccurred()
        print("triggerHapticFeedbackHeavy")
    }
}
