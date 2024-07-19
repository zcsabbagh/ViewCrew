//
//  AcceptMaster.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/19/24.
//

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
            Color.white.edgesIgnoringSafeArea(.all)
            Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            Image("friendAcceptBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
           
           if !accepted {
               AcceptView(person: person, accepted: $accepted, viewModel: viewModel)
           } else if accepted && !suggestedFriends.isEmpty {
                NewFriendView(person: person, viewModel: viewModel)
                // SuggestMoreView(person: person, suggestedFriends: suggestedFriends, viewModel: viewModel)
           }
           
        }

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
