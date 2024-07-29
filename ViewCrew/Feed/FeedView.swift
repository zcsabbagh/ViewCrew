//
//  File.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/9/24.
//

import Foundation
import SwiftUI
import VTabView
import SDWebImageSwiftUI
import Combine


struct Feed: View {
    @ObservedObject var viewModel: FeedViewModel
    @ObservedObject var friendsViewModel: NewNewFriendsViewModel
    @State private var selectedEmoji: String = ""
    @State private var showEmojiShower = false
    @State private var selectedPostType: PostType?
    @State private var showReportMenu: Bool = false
    @State private var showReportConfirmation: Bool = false
    @State private var refreshing: Bool = false

    var body: some View {
        ZStack {
            VStack {

                if refreshing {
                    VStack {
                        ProgressView()
                        Text("Refreshing...")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 100)
                }

                ZStack {
                    VerticalCarouselView(posts: viewModel.posts, selectedPostType: $selectedPostType, showReportMenu: $showReportMenu, onRefresh: {
                        refreshing = true
                        refreshPosts()
                    }, onLoadMore: {
                        loadMorePosts()
                    })
                        .padding(.bottom, 50)
                        .onChange(of: selectedPostType) { newPostType in
                            if let post = newPostType?.post {
                                print("Selected post: \(post.postID)")
                                print("Post type: \(post.post_type)")

//                                Task {
//                                    try await FirebaseNotificationGenerator.shared.sendContactJoinedNotification(fromUserDisplayName: "Boss", fromUserId: "shX0w5WsQ67eDhT0pib8", toUsers: ["shX0w5WsQ67eDhT0pib8"])
//                                }
//                                Task {
//                                    try await FirebaseNotificationGenerator.shared.sendFriendRequestNotification(fromUser: "shX0w5WsQ67eDhT0pib8", toUser: "shX0w5WsQ67eDhT0pib8")
//                                }
                            }
                        }
                    
                    EmojiScroll(selectedEmoji: $selectedEmoji)
                        .zIndex(1)
                        .padding(.top, 600)
                        .onChange(of: selectedEmoji) { newEmoji in
                            handleEmojiSelection(newEmoji)
                        }
                }
                .padding(.bottom, 30)
            }
            .background(Color.appBackground)
            .onChange(of: selectedPostType) { newPostType in
                if let post = newPostType?.post {
                    print("Current post on screen in Feed: \(post.postID)")
                    // Perform any actions needed when the current post changes
                }
            }
            
            if showEmojiShower {
                EmojiShowerView(emoji: selectedEmoji)
                    .zIndex(2)
                    .onTapGesture {
                        showEmojiShower = false
                    }
            }
            

        }
        .background(Color.appBackground)
        .confirmationDialog("Report Post", isPresented: $showReportMenu, titleVisibility: .visible) {
            Button("Report Post") {
                showReportConfirmation = true
                HapticFeedbackGenerator.shared.generateHapticLight()
            }
            Button("Cancel", role: .cancel) {
                HapticFeedbackGenerator.shared.generateHapticLight()
            }
        }
        .alert("Thank you! Post reported.", isPresented: $showReportConfirmation) {
            Button("OK", role: .cancel) {  HapticFeedbackGenerator.shared.generateHapticLight() }
        }
        .onReceive(friendsViewModel.$userProfile) { newUserProfile in
            viewModel.updateFriends(newUserProfile.friends)
        }
        .onChange(of: viewModel.friends) { _ in
            viewModel.fetchRecentPosts()
        }
    }

    private func handleEmojiSelection(_ emoji: String) {
        if !emoji.isEmpty {
            showEmojiShower = true
            if let post = selectedPostType?.post {
                viewModel.addReaction(to: post.postID, emoji: emoji)
                let userID = UserDefaults.standard.string(forKey: "userID") ?? "test"
                Task {
                    try await FirebaseNotificationGenerator.shared.sendReactPostNotification(fromUser: userID, forPoster: post.userId ?? "test", emoji: emoji)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                if let emojiShowerVC = (UIApplication.shared.windows.first?.rootViewController?.presentedViewController as? EmojiShowerViewController) {
                    emojiShowerVC.fadeOutEmojiShower()
                }
                showEmojiShower = false
                selectedEmoji = ""
            }
        }
    }

    private func refreshPosts() {
        refreshing = true
        viewModel.refreshPosts()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            refreshing = false
        }
    }

    private func loadMorePosts() {
        viewModel.loadMorePosts()
    }
}

struct VerticalCarouselView: View {
    let posts: [PostType]
    @Binding var selectedPostType: PostType?
    @Binding var showReportMenu: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    @State private var draggedOffset: CGFloat = 0

    var body: some View {
        VTabView(selection: $selectedPostType) {
            ForEach(posts, id: \.self) { postType in
                VStack(spacing: 5) {
                    MovieView(postType: postType, showReportMenu: $showReportMenu)
                }
                .tag(postType as PostType?)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(Color.appBackground)
        .onChange(of: selectedPostType) { newValue in
            if let newPostType = newValue {
                let post = newPostType.post
                print("Current post on screen: \(post.postID)")
                if newPostType == posts[max(0, posts.count - 2)] {
                    onLoadMore()
                }
            }
        }
    }
}

struct MovieView: View {
    let postType: PostType
    @Binding var showReportMenu: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            
            ZStack(alignment: .top) { // Align content to the top
                movieImage
                    .padding(.top, 20) // Adjust padding to move the image down
                HStack {
                    profileImage
                    name
                    Spacer()
                    reportButton
                    time
                }
                .padding(.trailing, 43)
                .padding(.leading, 40)
                .padding(.top, -45) // Adjust padding as needed
            }
            
            HStack (spacing: 15) {
                Spacer()
                imdb
                .padding(.trailing, 5)
                rottenTomatoes
                .padding(.leading, 5)
                Spacer()
            }
            
            HStack (spacing: 4) {
                title
                watchTrailer
                Spacer()
            }
            .padding(.leading, 70)
        }
    }
    
    var profileImage: some View {
        Group {
            if let profileImage = postType.post.profile?.profileImage {
                WebImage(url: URL(string: profileImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 19)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .cornerRadius(16)
                    .padding(.top, 30)
            }
        }
    }
    
    var name: some View {
        Group {
            Text("\(postType.post.profile?.username ?? "")")
                .font(.custom("Roboto-Regular", size: 17))
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
    
    var time: some View {
        Group {
            Text(postType.post.date ?? "")
                .font(.custom("Roboto-Regular", size: 12))
                .foregroundColor(.gray)
                .fontWeight(.light)
                .padding(.trailing)
        }
    }

    @ViewBuilder
    var rottenTomatoes: some View {
        if let tomatometerScore = postType.post.tomatoMeterScore {
            HStack (spacing: 5) {
                Image("rottentomatoes")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("\(tomatometerScore)%")
                    .font(.custom("Roboto-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    @ViewBuilder
    var imdb: some View {
        if let imdbRating = postType.post.imdbScore {
            HStack (spacing: 5) {
                Image("imdb")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("\(imdbRating)/10")
                    .font(.custom("Roboto-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    var movieImage: some View {
        Group {
            if let imageUrl = postType.post.previewImage {
                WebImage(url: URL(string: imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.buttonBackground, lineWidth: 3)
                    )
                    .cornerRadius(20)
                    .frame(width: 320, height: 426)
            }
        }
    }
    
    var title: some View {
        Group {
            if let season = postType.post.season, let episode = postType.post.episode {
                Text("Season \(season): Episode \(episode)")
                    .font(.custom("Roboto-Regular", size: 15))
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(.trailing)
            }
        }
    }

    var watchTrailer: some View {
        Group {
            if let youtubeTrailerURL = postType.post.youtubeTrailerURL,
               let url = URL(string: youtubeTrailerURL) {
                Button(action: {
                    UIApplication.shared.open(url)
                }) {
                    HStack (spacing: 2) {
                        Image(systemName: "play.circle")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        Text("Watch Trailer")
                            .font(.custom("Roboto-Regular", size: 14))
                            .foregroundColor(.white)
                            
                    }
                    .padding(4)
                    .background(Color.buttonBackground)
                    .cornerRadius(20)
                }
            }
        }
    }

    var reportButton: some View {
        Button(action: {
            self.showReportMenu = true
            HapticFeedbackGenerator.shared.generateHapticLight()
        }) {
            Image(systemName: "ellipsis")
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
        }
    }
}


struct EmojiShowerView: UIViewControllerRepresentable {
    let emoji: String
    
    func makeUIViewController(context: Context) -> EmojiShowerViewController {
        return EmojiShowerViewController(emoji: emoji)
    }
    
    func updateUIViewController(_ uiViewController: EmojiShowerViewController, context: Context) {}
}
