//
//  FriendAccept.swift
//  Roll
//
//  Created by Zane Sabbagh on 5/23/24.
//



/*
This handles the series of overlays when someone receives a friend request
*/
import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct IncomingFriendRequestView: View {

    @EnvironmentObject var viewModel: NewNewFriendsViewModel
    var person: PersonToAdd
    @State public var suggestedFriends: [PersonToAdd] = []
    @State private var accepted = false
    

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            if !accepted {
                AcceptView(person: person, accepted: $accepted, viewModel: viewModel)
            } else if accepted && !suggestedFriends.isEmpty {
                SuggestMoreView(person: person, suggestedFriends: suggestedFriends, viewModel: viewModel)
            }
           
        }
        .background(Color.red)

        /* if request is accepted but there are no suggestions to make, dismiss view */
        .onChange(of: accepted) { newValue in
            if newValue && suggestedFriends.isEmpty {
                print("request is accepted but there are no suggestions to make, dismiss view")
                viewModel.incomingRequests.removeFirst()
            }
        }

        /* get the friend profiles of this person */
        .onAppear {
            print("WE ARE ON ACCEPT FRIEND VIEW")
            let filteredFriends = person.friends.filter { friendID in
                friendID != viewModel.userID &&
                !viewModel.blockedUsers.contains(friendID) &&
                !viewModel.allRequests.contains(friendID) &&
                !viewModel.friendProfiles.contains(where: { $0.userID == friendID })
            }
            viewModel.createUsersFromUserIDs(filteredFriends) { suggestedFriends in
                self.suggestedFriends = suggestedFriends
            }
        }
    }
}



struct AcceptView: View {
    var person: PersonToAdd
    @Binding var accepted: Bool
    @ObservedObject var viewModel: NewNewFriendsViewModel
    @State private var loginHaptics = LoginHaptics()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                   viewModel.updateFriendRequestStatus(to: viewModel.userID, from: person.userID ?? "", newStatus: "declined")
                    loginHaptics.hapticEffectOne()
                    print("old size of incoming requests: \(viewModel.incomingRequests.count)")
                    if !viewModel.incomingRequests.isEmpty { viewModel.incomingRequests.removeFirst() }
                    print("new size of incoming requests: \(viewModel.incomingRequests.count)")
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
            } else {
                Text(String(person.name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Text(person.name)
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundColor(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 5)
            
            Text("\(person.friends.count) FRIENDS ON APP")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("wants to see your Vitalz")
                .font(.headline)
                .padding(.top, 10)
                .foregroundColor(.black)
            
            Button(action: {
                accepted = true
                viewModel.acceptFriendRequest(to: viewModel.userID, from: person.userID ?? "")
                viewModel.updateFriendRequestStatus(to: viewModel.userID, from: person.userID ?? "", newStatus: "accepted")
                loginHaptics.hapticEffectFive()
            }) {
                Text("+ Add")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 150, height: 50)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(10)
            }
            .padding(40)
        }
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}



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
