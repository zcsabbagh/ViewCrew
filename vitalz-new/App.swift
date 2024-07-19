//
//  vitalz_newApp.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/9/24.
//

import SwiftUI
import FirebaseCore
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct vitalz_newApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @StateObject var friendsViewModel = NewNewFriendsViewModel()
    @StateObject var profileViewModel = ProfileViewModel()
   
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                CustomTabBar(friendsViewModel: friendsViewModel, profileViewModel: profileViewModel)
                    .preferredColorScheme(.dark)
            } else {
                LoginMaster()
                    .preferredColorScheme(.dark)
            }
        }
    }
}

struct CustomTabBar: View {
    @State private var selectedTab = 0
    @ObservedObject var friendsViewModel: NewNewFriendsViewModel
    @StateObject private var feedViewModel: FeedViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    init(friendsViewModel: NewNewFriendsViewModel, profileViewModel: ProfileViewModel) {
        self.friendsViewModel = friendsViewModel
        self._feedViewModel = StateObject(wrappedValue: FeedViewModel(friends: friendsViewModel.userProfile.friends))
        self.profileViewModel = profileViewModel
        UITabBar.appearance().barTintColor = UIColor.black
    }

    var body: some View {
        if !friendsViewModel.incomingRequests.isEmpty {
            IncomingFriendRequestView(person: friendsViewModel.incomingRequests[0])
                .environmentObject(friendsViewModel)
        } else {
            TabView(selection: $selectedTab) {
                Feed(viewModel: feedViewModel, friendsViewModel: friendsViewModel)
                    .tabItem {
                        Image(systemName: "house")
                    }
                    .tag(0)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(Color.black, for: .tabBar)
                    .onTapGesture { HapticFeedbackGenerator.shared.generateHapticMedium() }
                
                FriendView(viewModel: friendsViewModel)
                    .tabItem {
                        Image(systemName: "person.2")
                    }
                    .tag(1)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(Color.black, for: .tabBar)
                    .onTapGesture { HapticFeedbackGenerator.shared.generateHapticMedium() }
                
                ProfileView(viewModel: profileViewModel)
                    .tabItem {
                        Image(systemName: "person")
                    }
                    .tag(2)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(Color.black, for: .tabBar)
                    .onTapGesture { HapticFeedbackGenerator.shared.generateHapticMedium() }
            }
            .accentColor(.white)
            .onAppear {
                UITabBarItem.appearance().badgeColor = .systemPink
                UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.systemPink]
                print("Length of incomingRequests: \(friendsViewModel.incomingRequests.count)")
            }
            .onChange(of: friendsViewModel.userProfile.friends) { newFriends in
                feedViewModel.updateFriends(newFriends)
            }
            .onChange(of: friendsViewModel.incomingRequests.count) { newCount in
                print("New number of incoming requests: \(newCount)")
            }
        }
    }
}