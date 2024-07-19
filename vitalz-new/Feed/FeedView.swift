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
    @State private var selectedPost: Post?
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
                    VerticalCarouselView(posts: viewModel.posts, selectedPost: $selectedPost, showReportMenu: $showReportMenu, onRefresh: {
                        refreshing = true
                        refreshPosts()
                    }, onLoadMore: {
                        loadMorePosts()
                    })
                        .padding(.bottom, 50)
                        .onChange(of: selectedPost) { newPost in
                            print("Selected post: \(newPost?.postID)")
                            print("Selected post ID: ")
                        }
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    handleEmojiSelection("❤️")
                                }
                        )
                    
                    EmojiScroll(selectedEmoji: $selectedEmoji)
                        .zIndex(1)
                        .padding(.top, 600)
                        .onChange(of: selectedEmoji) { newEmoji in
                            handleEmojiSelection(newEmoji)
                        }
                }
                .padding(.bottom, 50)
            }
            .background(Color.appBackground)
            .onChange(of: selectedPost) { newPost in
                if let post = newPost {
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
            viewModel.addReaction(to: selectedPost?.postID ?? "test", emoji: emoji)
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

struct EmojiShowerView: UIViewControllerRepresentable {
    let emoji: String
    
    func makeUIViewController(context: Context) -> EmojiShowerViewController {
        return EmojiShowerViewController(emoji: emoji)
    }
    
    func updateUIViewController(_ uiViewController: EmojiShowerViewController, context: Context) {}
}

struct VerticalCarouselView: View {
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var showReportMenu: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    @State private var draggedOffset: CGFloat = 0

    var body: some View {
        VTabView(selection: $selectedPost) {
            ForEach(posts) { post in
                VStack (spacing: 5) {
                    MovieView(post: post, showReportMenu: $showReportMenu)
                }
                .tag(post as Post?)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(Color.appBackground)
        .onChange(of: selectedPost) { newValue in
            if let newPost = newValue {
                print("Current post on screen: \(newPost.postID)")
                if newPost == posts[max(0, posts.count - 2)] {
                    onLoadMore()
                }
            }
        }
    }
}

struct MovieView: View {
    let post: Post
    @Binding var showReportMenu: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            
            ZStack {
                movieImage
                HStack {
                    profileImage
                        
                    name
                    time
                    reportButton
                    Spacer()
                }
                .padding(.leading, 40)
                .padding(.bottom, 440)
            }
            HStack {
                title
                    .padding(.leading, 70)
                    .padding(.top, -60)
                Spacer()
                    
            }
        }
    }
    

    var profileImage: some View {
        Group {
            if let profileImage = post.profile?.profileImage {
                WebImage(url: URL(string: profileImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .cornerRadius(16)
                    .padding(.top, 40)
            }
            
        }

    }
    
    var name: some View {
        Group {
            Text("\(post.profile?.username ?? "")")
                .font(.custom("Roboto-Regular", size: 17))
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
    
    var time: some View {
        Group {
            Text(post.date ?? "")
                .font(.custom("Roboto-Regular", size: 12))
                .foregroundColor(.gray)
                .fontWeight(.light)
                .padding(.trailing)
        }
    }
    
    
    var movieImage: some View {
        Group {
            if let imageUrl = post.previewImage {
                WebImage(url: URL(string: imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.buttonBackground, lineWidth: 3)
                    )
                    .cornerRadius(20)
                    .frame(width: 300, height: 400)
            }
        }
    }
    
    var title: some View {
        Group {
            if let season = post.season, let episode = post.episode {
                Text("Season \(season): Episode \(episode)")
                    .font(.custom("Roboto-Regular", size: 17))
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(.trailing)
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




//struct Feed_Previews: PreviewProvider {
//    static var previews: some View {
//        Feed(viewModel: FeedViewModel())
//    }
//}



// for testing


//@State var zane: Profile = Profile(username: "zanesabbagh", name: "Zane", profileImage: "https://firebasestorage.googleapis.com:443/v0/b/candid2024-9f0fc.appspot.com/o/userImages%2FE21C7E47-DA97-43A7-8312-DF98278C2D77.jpg?alt=media&token=cc335af6-2276-4656-a483-7068913d424e")
//VerticalCarouselView(posts: [
//    Post(title: "Pain Hustlers", timeAgo: "2", previewImage: "https://m.media-amazon.com/images/M/MV5BNWMxYjNhZmEtNDBjZi00ZjVlLTg0NWUtMmQzNDZhYWUxZmIyXkEyXkFqcGdeQXVyODE5NzE3OTE@._V1_.jpg", season: nil, episode: nil, profile: zane),
//    Post(title: "Spenser Confidential", timeAgo: "5", previewImage: "https://m.media-amazon.com/images/M/MV5BMTdkOTEwYjMtNDA1YS00YzVlLTg0NWUtMmQzNDZhYWUxZmIyXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg", season: nil, episode: nil, profile: zane),
//    Post(title: "The Tinder Swindler", timeAgo: "3", previewImage: "https://m.media-amazon.com/images/M/MV5BMTkwMTg2YWYtOGU5MS00YTdhLTg4N2QtYzcyZDE0MTlmNDU3XkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_.jpg", season: nil, episode: nil, profile: zane)
//])


struct Ratings: View {
    let ratings: [Int]

    var body: some View {
        HStack(spacing: 5) {
            Button(action: {
                // Action for Rotten Tomatoes button
                HapticFeedbackGenerator.shared.generateHapticLight()
            }) {
                HStack {
                        Image("rottentomatoes")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("70")
                            .font(.custom("Roboto-Regular", size: 12))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(8)
                    .background(Color.clear)
//                    .background(Color.buttonBackground)
                    .cornerRadius(10)
                }

                Button(action: {
                    // Action for IMDb button
                    HapticFeedbackGenerator.shared.generateHapticLight()
                }) {
                    HStack {
                        Image("imdb")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("8.8")
                            .font(.custom("Roboto-Regular", size: 12))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(8)
//                    .background(Color.buttonBackground)
                    .background(Color.clear)
                    .cornerRadius(10)
                }

                Button(action: {
                    // Action for Metacritic button
                    HapticFeedbackGenerator.shared.generateHapticLight()
                }) {
                    HStack {
                        Image("metacritic")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("50")
                            .font(.custom("Roboto-Regular", size: 12))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(8)
//                    .background(Color.buttonBackground)
                    .background(Color.clear)
                    .cornerRadius(10)
                }
            }
        }
    }


/* probably not needed anymore */
struct FeedProfile: View {
    let post: Post

    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            if let profileImage = post.profile?.profileImage {
                WebImage(url: URL(string: profileImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .cornerRadius(16)
            }
            Text("\(post.profile?.username ?? "")")
                
                .font(.custom("Roboto-Regular", size: 17))
                .fontWeight(.semibold)
                .padding(.bottom, -5)
            Text("\(post.timeAgo) hours ago")
                .font(.custom("Roboto-Regular", size: 14))
                .fontWeight(.light)
                .foregroundColor(.gray)

        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(20)
    }
}