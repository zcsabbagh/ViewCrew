//
//  SuggestView.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/19/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct SuggestMoreView: View {
    var person: PersonToAdd
    var suggestedFriends: [PersonToAdd]
    @ObservedObject var viewModel: NewNewFriendsViewModel
    @State private var loginHaptics = LoginHaptics()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    loginHaptics.hapticEffectOne()
                    viewModel.incomingRequests.removeFirst()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 20)
            
            if let imageUrl = person.contactImageURL, let url = URL(string: imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding(.top, -50)
            } else {
                Text(String(person.name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
                    .padding(.top, -50)
            }
            
            
            Text("Maybe you know some of \(person.name.components(separatedBy: " ").first ?? "")'s friends")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .foregroundColor(.black)
            
            ScrollView {
                LazyVStack {
                    ForEach(suggestedFriends, id: \.name) { friend in
                        AddContact(person: friend, viewModel: viewModel, messageViewShown: .constant(false), recepients: .constant([]))
                            .padding(.horizontal, 20)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.bottom, 20)
            .frame(maxHeight: 500) // Adjust this value as needed
            .padding(.top, 10)
        }
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .fixedSize(horizontal: false, vertical: true) // This ensures the VStack only takes as much vertical space as needed
    }
}

