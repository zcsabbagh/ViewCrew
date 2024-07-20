//
//  NewFriend.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/19/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct NewFriendView: View {
    var person: PersonToAdd
    @ObservedObject var viewModel: NewNewFriendsViewModel
    @State private var loginHaptics = LoginHaptics()
    @State private var me: PersonToAdd
    
    init(person: PersonToAdd, viewModel: NewNewFriendsViewModel) {
        self.person = person
        self.viewModel = viewModel
        
        // Initialize 'me' with data from UserDefaults
        let defaults = UserDefaults.standard
        let name = defaults.string(forKey: "displayName") ?? ""
        let username = defaults.string(forKey: "username") ?? ""
        // var profileImageURL = defaults.string(forKey: "profileImageURL")
        let profileImageURL = "https://firebasestorage.googleapis.com:443/v0/b/candid2024-9f0fc.appspot.com/o/userImages%2F074D68FE-C019-4025-91B8-2420E12B70CB.jpg?alt=media&token=2fe0028e-52f5-4dcd-a639-0d81632facf9"
        let friendUserIds = defaults.array(forKey: "friendUserIds") as? [String] ?? []
        let userId = defaults.string(forKey: "userId") ?? ""
        
        _me = State(initialValue: PersonToAdd(
            name: name,
            contactImageURL: profileImageURL,
            contactImage: nil,
            friends: friendUserIds,
            phoneNumber: nil,
            userID: userId,
            username: username,
            isFriend: nil
        ))
    }
    
    var body: some View {
        ZStack {
            // Content
            VStack(alignment: .center) {
                // closeButton
                Image("newFriendsText")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .padding(.top, 100)
                
                Spacer()
                HStack {
                    Image("lightning")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding(.leading, 35)
                        .padding(.bottom, -35)
                    Spacer()
                }
                
                personProfileImage(for: me, isUser: true)
                personProfileImage(for: person, isUser: false)
                    .padding(.top, -25)
                
                HStack {
                    Spacer()
                    Image("lightning")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding(.trailing, 35)
                        .padding(.top, -35)
                }
                Spacer()
                newFriends
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            loginHaptics.hapticEffectFour()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                viewModel.incomingRequests.removeFirst()
            }
        }
        .onTapGesture {
            viewModel.incomingRequests.removeFirst()
        }
    }
    
    private var newFriends: some View {
        Text("\(person.name.split(separator: " ").first?.lowercased() ?? "") & \((me.name.isEmpty ? "me" : me.name.split(separator: " ").first?.lowercased() ?? ""))")
            .font(.custom("Roboto-Medium", size: 20))
            .foregroundColor(.white)
            .padding(.bottom, 30)
    }
    


    private func personProfileImage(for person: PersonToAdd, isUser: Bool) -> some View {
        Group {
            if let imageUrl = person.contactImageURL, let url = URL(string: imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.appPurple, lineWidth: 4))
                    .rotationEffect(.degrees(isUser ? 30 : -30))
            } else {
                Text(person.initials)
                    .foregroundColor(.white)
                    .frame(width: 150, height: 150)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.appPurple, lineWidth: 4))
                    .rotationEffect(.degrees(isUser ? 30 : -30))
            }
        }
    }
    
}