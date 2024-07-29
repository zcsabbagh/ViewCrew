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
import AVKit

struct Feed: View {
    @ObservedObject var viewModel: FeedViewModel
    @ObservedObject var friendsViewModel: NewNewFriendsViewModel
    @State private var selectedEmoji: String = ""
    @State private var showEmojiShower = false
    @State private var selectedPostType: PostType?
    @State private var showReportMenu: Bool = false
    @State private var showReportConfirmation: Bool = false
    @State private var refreshing: Bool = false
    @State private var showAddWidgetSheet: Bool = false

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

                               Task {
                                   try await FirebaseNotificationGenerator.shared.sendContactJoinedNotification(fromUserDisplayName: "Boss", fromUserId: "shX0w5WsQ67eDhT0pib8", toUsers: ["shX0w5WsQ67eDhT0pib8"])
                               }
                               Task {
                                   try await FirebaseNotificationGenerator.shared.sendFriendRequestNotification(fromUser: "shX0w5WsQ67eDhT0pib8", toUser: "shX0w5WsQ67eDhT0pib8")
                               }
                            }
                        }
                    
                    EmojiScroll(selectedEmoji: $selectedEmoji)
                        .zIndex(1)
                        .padding(.top, 600)
                        .onChange(of: selectedEmoji) { newEmoji in
                            handleEmojiSelection(newEmoji)
                        }

                    WidgetButton(showAddWidgetSheet: $showAddWidgetSheet)
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
            .sheet(isPresented: $showAddWidgetSheet) {
                AddWidgetView()
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

struct WidgetButton: View {
    @Binding var showAddWidgetSheet: Bool
   @AppStorage("hasWidgetBeenPressed") private var hasWidgetBeenPressed = false

    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    showAddWidgetSheet = true
                    hasWidgetBeenPressed = true
                    HapticFeedbackGenerator.shared.generateHapticLight()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Group {
                                if !hasWidgetBeenPressed {
                                    Circle()
                                        .fill(LinearGradient(gradient: Gradient(colors: [.purple, .green]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .scaleEffect(isAnimating ? 1.4 : 1.0)
                                } else {
                                    Circle().fill(Color.gray.opacity(0.5))
                                }
                            }
                        )
                }
                .padding(.leading, 20)
                .padding(.top, 5)
                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                Spacer()
            }
            Spacer()
        }
        .onAppear {
            if !hasWidgetBeenPressed {
                isAnimating = true
            }
        }
    }
}

struct AddWidgetView: View {
    @State private var player: AVPlayer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Text("Add Home Screen Widget")
                        .font(.title)
                        .padding(.top, 20)
                    
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(width: min(geometry.size.width * 0.8, geometry.size.height * 0.7 / 2.1641025641),
                                   height: min(geometry.size.width * 0.8 * 2.1641025641, geometry.size.height * 0.7))
                            .aspectRatio(1 / 2.1641025641, contentMode: .fit)
                            .clipped()
                            .disabled(true)
                            .cornerRadius(20)
                    } else {
                        Text("Video tutorial not available")
                            .foregroundColor(.gray)
                            .frame(width: min(geometry.size.width * 0.8, geometry.size.height * 0.7 / 2.1641025641),
                                   height: min(geometry.size.width * 0.8 * 2.1641025641, geometry.size.height * 0.7))
                    }

                    Button(action: {
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                        HapticFeedbackGenerator.shared.generateHapticLight()
                    }) {
                        Text("Add Widget")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.purple, .green]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(15)
                    }
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                
                // New dismiss button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            HapticFeedbackGenerator.shared.generateHapticLight()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.gray.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            setupVideo()
        }
    }
    
    private func setupVideo() {
        guard let url = Bundle.main.url(forResource: "WidgetTutorial", withExtension: "MP4") else {
            print("Video file not found")
            return
        }
        
        player = AVPlayer(url: url)
        player?.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

extension AVPlayer {
    static func setupAutoPlayAndLoop(for resourceName: String) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "mp4") else {
            print("Video file not found")
            return
        }
        
        let player = AVPlayer(url: url)
        player.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
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
            } else {
                Text("Season 0: Episode 0")
                    .font(.custom("Roboto-Regular", size: 15))
                    .foregroundColor(Color.clear)
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