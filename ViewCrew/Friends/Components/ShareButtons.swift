//
//  ShareButtons.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/11/24.
//

import Foundation
import SwiftUI


struct ShareButtons: View {
    @State private var shareLink = "https://apps.apple.com/us/app/view-crew-streaming-widget/id6569239199"
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Sharing Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
        shareViaApp(urlString: "whatsapp://send?text=\(shareLink)", appName: "WhatsApp")
    }
    
    // Messenger Sharing
    private func shareOnMessenger() {
        shareViaApp(urlString: "fb-messenger://share/?link=\(shareLink)", appName: "Messenger")
    }
    
    // iMessage Sharing
    private func shareOniMessage() {
        shareViaApp(urlString: "sms:&body=\(shareLink)", appName: "iMessage")
    }
    
    // Telegram Sharing
    private func shareOnTelegram() {
        let encodedLink = shareLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        shareViaApp(urlString: "tg://msg?text=\(encodedLink)", appName: "Telegram")
    }
    
    // Instagram Sharing
    private func shareOnInstagram() {
        shareViaApp(urlString: "instagram://app", appName: "Instagram")
    }
    
    // Snapchat Sharing
    private func shareOnSnapchat() {
        shareViaApp(urlString: "snapchat://?attachText=\(shareLink)", appName: "Snapchat")
    }
    
    private func shareViaApp(urlString: String, appName: String) {
        HapticFeedbackGenerator.shared.generateHapticLight()
        guard let url = URL(string: urlString) else {
            alertMessage = "Invalid URL for \(appName)"
            showAlert = true
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                // Check if the app is installed
                if UIApplication.shared.canOpenURL(url) {
                    // The app is installed, but the user likely canceled the action
                    // Do nothing in this case
                } else {
                    // The app is not installed
                    alertMessage = "You need \(appName) to share via \(appName)"
                    showAlert = true
                }
            }
        }
    }
}