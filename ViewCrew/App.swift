//
//  vitalz_newApp.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/9/24.
//

import SwiftUI
import FirebaseCore
import CoreData
import AmplitudeSwift
import UserNotifications
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let amplitude = Amplitude(configuration: Configuration(
        apiKey: "f8da5e324708d7407ecad7b329e154c4"
    ))
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set up notifications
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        amplitude.track(
            eventType: "App Open",
            eventProperties: ["my event prop key": "my event prop value"]
        )
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // Here you would typically send this token to your server
        if let token = fcmToken {
            FirebaseCreateUserModel().updateFCMToken(token)
        }
    }
}

@main
struct vitalz_newApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                CustomTabBar()
                    .defaultAppStorage(UserDefaults(suiteName: "group.viewcrew.ShareDefaults")!)
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
    @StateObject var friendsViewModel = NewNewFriendsViewModel()
    @StateObject private var feedViewModel: FeedViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    
    init() {
        let friendsVM = NewNewFriendsViewModel()
        self._friendsViewModel = StateObject(wrappedValue: friendsVM)
        self._feedViewModel = StateObject(wrappedValue: FeedViewModel(friends: friendsVM.userProfile.friends))
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel())
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