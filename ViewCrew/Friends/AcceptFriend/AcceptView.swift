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

struct AcceptView: View {
    var person: PersonToAdd
    @Binding var accepted: Bool
    @ObservedObject var viewModel: NewNewFriendsViewModel
    @State private var loginHaptics = LoginHaptics()

    var body: some View {
        ZStack {
            
            // Content
            VStack() {
                // closeButton
                nameText

                
                Spacer()
                HStack{
                    Image("lightning")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding(.horizontal, 35)
                        .padding(.bottom, -35)
                    Spacer()
                }
                usernameText
                profileImage
                friendCountText
                HStack{
                    Spacer()
                    Image("lightning")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding(.horizontal, 35)
                        .padding(.top, -35) 
                }
                Spacer()
                addButton
                cancelButton
            }
            .padding(.horizontal, 20)
        }
        .edgesIgnoringSafeArea(.all)
    }


    private var profileImage: some View {
        Group {
            if let imageUrl = person.contactImageURL, let url = URL(string: imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .cornerRadius(40)
                    .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.appPurple, lineWidth: 4))
            } else {
                Text(person.initials)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(40)
                    .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.appPurple, lineWidth: 4))
            }
        }
    }

    private var nameText: some View {
        Text("\(Text(person.name).font(.custom("RobotoCondensed-Bold", size: 30)).bold().foregroundColor(.white)) wants to be your friend")
            .font(.custom("RobotoCondensed-Medium", size: 30))
            .foregroundColor(.white.opacity(0.8))
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 25)
            .padding(.top, 90)
    }

    private var usernameText: some View {
        Text(person.username?.isEmpty == true ? "" : "@\(person.username ?? "")")
            .font(.custom("RobotoCondensed-Medium", size: 16))
            .foregroundColor(.appPurple)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.center)
            .padding(.vertical, 2)
            .padding(.leading, -20)
    }


    private var friendCountText: some View {
        Text("\(person.friends.count) friends on app")
            .font(.custom("RobotoCondensed-Medium", size: 18))
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.8))
            .cornerRadius(10)
            .padding()
    }
    private var addButton: some View {
        Button(action: acceptFriendRequest) {
            Text("Accept Request")
                .font(.custom("Roboto-Medium", size: 20))
                .foregroundColor(.white)
                .padding()
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.appPurple, Color.appPurple.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(30)
        }
        .padding(.horizontal, UIScreen.main.bounds.width * 0.12)
    }

    private var cancelButton: some View {
        Button(action: rejectFriendRequest) {
            Text("Deny")
                .font(.custom("Roboto-Medium", size: 20))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(15)
        .padding(.bottom, 30)
    }

    // MARK: - Helper Methods

    private func declineFriendRequest() {
        viewModel.updateFriendRequestStatus(to: viewModel.userID, from: person.userID ?? "", newStatus: "declined")
        loginHaptics.hapticEffectOne()
        print("old size of incoming requests: \(viewModel.incomingRequests.count)")
        if !viewModel.incomingRequests.isEmpty { viewModel.incomingRequests.removeFirst() }
        print("new size of incoming requests: \(viewModel.incomingRequests.count)")
    }

    private func acceptFriendRequest() {
        accepted = true
        viewModel.acceptFriendRequest(to: viewModel.userID, from: person.userID ?? "")
        viewModel.updateFriendRequestStatus(to: viewModel.userID, from: person.userID ?? "", newStatus: "accepted")
        loginHaptics.hapticEffectFive()
    }

    private func rejectFriendRequest() {
        accepted = false
        viewModel.updateFriendRequestStatus(to: viewModel.userID, from: person.userID ?? "", newStatus: "declined")
        loginHaptics.hapticEffectFive()
    }
}

// MARK: - Extensions

extension PersonToAdd {
    var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined())
    }
}
