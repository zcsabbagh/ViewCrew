//
//  Friends.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/11/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct FriendsListView: View {
    @Binding var searchText: String
    @ObservedObject var viewModel: NewNewFriendsViewModel

    var body: some View {
        
        LazyVStack (spacing: 8) {

            if viewModel.friendProfiles.count > 0 || viewModel.matchedFriends.count > 0 {
                Text("FRIENDS")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 5)
            }
           if searchText != "" {
               ForEach(viewModel.matchedFriends, id: \.name) { person in
                    Friend(person: person, viewModel: viewModel)
               }
            } else {
                ForEach(viewModel.friendProfiles, id: \.name) { person in
                    Friend(person: person, viewModel: viewModel)
                }
           }
        }
    }
}

struct Friend: View {
    var person: PersonToAdd
    @ObservedObject var viewModel: NewNewFriendsViewModel
    
    @State private var showActionSheet = false
    
    let PROFILE_RADIUS: CGFloat = 15
    let PROFILE_SIZE: CGFloat = 50

    var body: some View {
        HStack {
            // Image with app overlay
            ZStack(alignment: .bottomTrailing) {
                if let imageUrl = person.contactImageURL, let url = URL(string: imageUrl) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: PROFILE_SIZE, height: PROFILE_SIZE)
                        .cornerRadius(PROFILE_RADIUS)
                        .overlay(
                            RoundedRectangle(cornerRadius: PROFILE_RADIUS)
                                .stroke(Color.black, lineWidth: 1)
                        )
                } else if let image = person.contactImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: PROFILE_SIZE, height: PROFILE_SIZE)
                        .cornerRadius(PROFILE_RADIUS)
                        .overlay(
                            RoundedRectangle(cornerRadius: PROFILE_RADIUS)
                                .stroke(Color.black, lineWidth: 1)
                        )
                } else {
                    Text(String(person.name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()))
                        .foregroundColor(.white)
                        .frame(width: PROFILE_SIZE, height: PROFILE_SIZE)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(PROFILE_RADIUS)
                        .overlay(
                            RoundedRectangle(cornerRadius: PROFILE_RADIUS)
                                .stroke(Color.black, lineWidth: 1)
                        )

                    
                    Image("ic_imessage")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 2, y: 2)
                }

            }

            // Name and Friends Info
            VStack(alignment: .leading, spacing: 6) {
                Text(person.name)
                    .font(.title3)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                Text(person.username ?? person.name.lowercased())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fontWeight(.light)
            }
            .padding(.leading, 8)
            Spacer()

            /* Placeholder button */
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.buttonBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .transition(.scale)
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Options"),
                    buttons: [
                        .default(Text("Unfriend")) {
                            viewModel.unfriendUser(otherUserID: person.userID ?? "")
                        },
                        .destructive(Text("Block")) {
                            viewModel.blockUser(otherUserID: person.userID ?? "")
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
}
