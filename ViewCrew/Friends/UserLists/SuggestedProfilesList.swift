//
//  NonFriendProfiles.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/11/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct AddContactsListView: View {
    @Binding var searchText: String
    @ObservedObject var viewModel: NewNewFriendsViewModel
    @Binding var isMessageComposerPresented: Bool
    @Binding var messageRecepients: [String]

    var body: some View {
        LazyVStack {
            Text("SUGGESTIONS")
                .font(.custom("Roboto-Regular", size: 15))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)
            if searchText != "" {
                ForEach(viewModel.matchedContacts, id: \.name) { person in
                    AddContact(person: person, viewModel: viewModel, messageViewShown: $isMessageComposerPresented, recepients: $messageRecepients)
                }
                ForEach(viewModel.searchResults, id: \.name) { person in
                    AddContact(person: person, viewModel: viewModel, messageViewShown: $isMessageComposerPresented, recepients: $messageRecepients)
                }
            } else {
                ForEach(viewModel.suggestionsOnApp, id: \.name) { person in
                    AddContact(person: person, viewModel: viewModel, messageViewShown: $isMessageComposerPresented, recepients: $messageRecepients)
                }
                ForEach(viewModel.suggestionsFromContacts, id: \.name) { person in
                    AddContact(person: person, viewModel: viewModel, messageViewShown: $isMessageComposerPresented, recepients: $messageRecepients)
                }
            }
        }
    }
}



/* NEED TO MAKE SURE YOU DON'T SHOW PERSON on both app and in contacts */
struct AddContact: View {
    var person: PersonToAdd
    @ObservedObject var viewModel: NewNewFriendsViewModel
    @Binding var messageViewShown: Bool
    @Binding var recepients: [String]
    
    @State private var added: Bool = false
    
    
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


                    Image("ic_imessage")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 2, y: 2)
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
                    .font(.custom("Roboto-Medium", size: 17))
                    .foregroundColor(.white)
                Text("\(person.friends.count) \(person.friends.count == 1 ? "FRIEND" : "FRIENDS") ON VITAL")
                    .font(.custom("Roboto-Regular", size: 10))
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
            Spacer()

            /* Add button */
            Button(action: {
                if !added {
                    HapticFeedbackGenerator.shared.generateHapticMedium()
                   
                    withAnimation { self.added.toggle() }
                      if let imageUrl = person.contactImageURL {
                        viewModel.createFriendRequest(to: person.userID ?? "", from: viewModel.userID)
                      } else {
                        recepients = [person.phoneNumber ?? ""]
                        messageViewShown = true
                      }

                }
            }) {
                if !added {
                    Image(systemName: "plus")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .transition(.scale)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .transition(.scale)
                }
            }
           
        }
    }
}
