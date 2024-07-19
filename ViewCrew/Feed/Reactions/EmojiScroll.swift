//
//  EmojiScroll.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/10/24.
//

import Foundation
import SwiftUI

struct EmojiScroll: View {
    
    @Binding var selectedEmoji: String
    @State private var emojis: [String] = ["❤️", "😄", "😛", "👀", "🔥", "👏", "💩"]
    // @Binding var triggerEmojiAnimation: Bool
    
    
    var body: some View {
        GeometryReader { fullGeometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(emojis, id: \.self) { emoji in
                            GeometryReader { itemGeometry in
                                Button(action: {
                                    HapticFeedbackGenerator.shared.generateHapticHeavy()
                                    selectedEmoji = emoji
//                                    triggerEmojiAnimation = true
                                }) {
                                    EmojiCircle(emoji: emoji, selectedEmoji: selectedEmoji)
                                        .frame(width: 55, height: 55)
                                }
                                .id(emoji)
                            }
                            .frame(width: 60, height: 705)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        .frame(height: 75)
        .background(Color.clear.opacity(0))
    }
}


struct EmojiCircle: View {
    
    var emoji: String
    var selectedEmoji: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(emoji == selectedEmoji ? Color.gray.opacity(0.10) : Color.gray.opacity(0.15))
                .frame(width: 55, height: 55)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            Text(emoji)
                .font(.system(size: 30))
                .foregroundColor(.white)
        }
    }
}
