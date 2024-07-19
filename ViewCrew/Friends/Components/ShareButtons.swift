//
//  ShareButtons.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/11/24.
//

import Foundation
import SwiftUI


struct ShareButtons: View {
    @State private var shareLink = "tinyurl.com/joinroll"
    var body: some View {
        
        VStack {
            Text("SHARE VIA")
                .font(.custom("Roboto-Regular", size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // WhatsApp Share Button
                    shareButton(iconName: "ic_whatsapp", label: "WhatsApp", action: shareOnWhatsApp)
                    
                    // Messenger Share Button
                    shareButton(iconName: "ic_messenger", label: "Messenger", action: shareOnMessenger)
                    
                    // iMessage Share Button
                    shareButton(iconName: "ic_imessage", label: "iMessage", action: shareOniMessage)
                    
                    // Telegram Share Button
                    shareButton(iconName: "ic_telegram", label: "Telegram", action: shareOnTelegram)
                    
                    // Instagram Share Button
                    shareButton(iconName: "ic_instagram", label: "Instagram", action: shareOnInstagram)
                    
                }
            }
        }
        
    }
    
    
    
    // Share Button View
    private func shareButton(iconName: String, label: String, action: @escaping () -> Void) -> some View {
        VStack {
            Button(action: action) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .frame(width: 62, height: 62)
            }
        }
    }
    
    // WhatsApp Sharing
    private func shareOnWhatsApp() {
        HapticFeedbackGenerator.shared.generateHapticLight()
        let urlString = "whatsapp://send?text=\(shareLink)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Messenger Sharing
    private func shareOnMessenger() {
        HapticFeedbackGenerator.shared.generateHapticLight()
        let urlString = "fb-messenger://share/?link=\(shareLink)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // iMessage Sharing
    private func shareOniMessage() {
        HapticFeedbackGenerator.shared.generateHapticLight()
        let urlString = "sms:&body=\(shareLink)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Telegram Sharing
    private func shareOnTelegram() {
        HapticFeedbackGenerator.shared.generateHapticLight()
        let encodedLink = shareLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "tg://msg?text=\(encodedLink)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Instagram Sharing
    private func shareOnInstagram() {
        HapticFeedbackGenerator.shared.generateHapticLight()
        let urlString = "instagram://app"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [.universalLinksOnly: false]) { success in
                if !success {
                    // If Instagram App isn't installed, open a web page with the shared link
                    let webURL = URL(string: "https://www.instagram.com/direct/inbox/")
                    UIApplication.shared.open(webURL!)
                }
            }
        }
    }
    
    // Snapchat Sharing
    private func shareOnSnapchat() {
        HapticFeedbackGenerator.shared.generateHapticLight()
        let urlString = "snapchat://?attachText=\(shareLink)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
