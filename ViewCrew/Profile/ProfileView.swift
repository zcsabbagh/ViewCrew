//
//  Created by Zane Sabbagh on 7/9/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            // Top bar with share and settings buttons
            ProfileTopPanel()
            
            // Profile picture and username
            ProfileInformation(viewModel: viewModel)
            .padding(.top, -30)
            
            // Recently watched
            RecentlyWatched(posts: viewModel.recentWatches)
            
            // Last week statistics box
            LastWeek(viewModel: viewModel)
            
            // Scroll of user's genres
            GenresScroll(viewModel: viewModel)
                .padding(.bottom, 50)
            
            Spacer()
        }
        .padding(.top, 20)
        .padding(.bottom, 50)
        .background(Color.appBackground)
        .foregroundColor(.white)
        .edgesIgnoringSafeArea(.all)
    }
}




/* components ordered by vertical positioning */
struct ProfileTopPanel: View {
    @State private var showingProfileOptions = false
    
    var body: some View {
        HStack {
            Button(action: {
                HapticFeedbackGenerator.shared.generateHapticMedium()
                // Share action
            }) {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color.clear)
                    .padding(10)
                    .background(Color.clear)
                    .cornerRadius(12)
            }
            Spacer()
            Button(action: {
                showingProfileOptions = true
                HapticFeedbackGenerator.shared.generateHapticMedium()
            }) {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(10)
                    .background(Color.buttonBackground)
                    .cornerRadius(12)
            }
        }
        .padding(.top, 50)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showingProfileOptions) {
            ProfileOptions()
        }
       
    }

}

struct ProfileInformation: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack (spacing: 5) {
        HStack (spacing: 10) {
            WebImage(url: URL(string: viewModel.profilePicture))
                .resizable()
                .indicator(.activity) // Show activity indicator while loading
                .transition(.fade(duration: 0.5)) // Fade transition with duration
                .scaledToFill()
                .frame(width: 100, height: 100)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white, lineWidth: 2)
                )
            .padding(.leading, 5)
            
        }
        Text(viewModel.displayName)
            .font(.custom("Roboto-Bold", size: 20))
            .fontWeight(.bold)
        Text("@\(viewModel.username)")
            .foregroundColor(.white.opacity(0.8))
            .font(.custom("Roboto-Regular", size: 14))
    }
    .padding(.top, -10)
    }

}

struct RecentlyWatched: View {
    var posts: [Post]

    var body: some View {
        VStack (spacing: 3) {
            HStack {
                Image("Recently")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(posts, id: \.self) { post in
                        ProfileMovie(movie: post)
                    }
                }
                
            }
        }
    }
}


struct ProfileMovie: View {
    var movie: Post

    var body: some View {
        VStack {
            WebImage(url: URL(string: movie.previewImage ?? ""))
                .resizable()
                .indicator(.activity) // Show activity indicator while loading
                .transition(.fade(duration: 0.5)) // Fade transition with duration
                .scaledToFill()
                .frame(width: 150, height: 200)
                .background(Color.white)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.buttonBackground, lineWidth: 0.5)
                )
            Text(movie.title)
                .font(.custom("Roboto-Bold", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: 140)
        }
            
    }
}



struct LastWeek: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack (spacing: 10) {
            Text("This Week You Watched")
                .font(.custom("Roboto-Bold", size: 20))
                .foregroundColor(.gray)
                .fontWeight(.bold)
            HStack {
                ProfileStatsBox(title: "MINS", value: viewModel.lastWeekStats[0])
                ProfileStatsBox(title: "EPISODES", value: viewModel.lastWeekStats[1])
                ProfileStatsBox(title: "MOVIES", value: viewModel.lastWeekStats[2])
            }
        }
    }
}

struct ProfileStatsBox: View {
    var title: String
    var value: Int
    
    var body: some View {
        VStack {
            Spacer()
            Text(String(format: "%.0f", Double(value)))
                .font(.custom("Bebas_Neue", size: 60))
                .fontWeight(.black)
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(title)
                .font(.custom("Bebas_Neue", size: 12))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width / 5, height: 80) // Fixed height
        .padding()
        .background(
            Image("StatsButton")
                .resizable()
                .scaledToFill()
        )
        .cornerRadius(15)
    }

}


struct GenresScroll: View {
    @ObservedObject var viewModel: ProfileViewModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack {
                GenresRow(viewModel: viewModel)
                GenresRow(viewModel: viewModel)
                    .padding(.leading, 15)
            }

        }
        .padding()
    }
}

struct GenresRow: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 3) {
            ForEach(viewModel.genres.shuffled(), id: \.self) { genre in
                Text(genre)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.brightWhiteText)
                    .padding(8)
                    .background(Color.buttonBackground)
                    .cornerRadius(25)
            }
        }
    }
}



//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView(viewModel: ProfileViewModel(displayName: "zane", username: "@zane.388", profilePicture: "https://firebasestorage.googleapis.com:443/v0/b/candid2024-9f0fc.appspot.com/o/userImages%2F4CA18D26-EE1E-4474-AFF4-99CBC86BF3BE.jpg?alt=media&token=02af248b-d57f-44dc-892c-7843865b15e0"))
//    }
//}


// let posts = [
//     Post(postID: "", title: "Pain Hustlers", timeAgo: "2", previewImage: "https://m.media-amazon.com/images/M/MV5BNWMxYjNhZmEtNDBjZi00ZjVlLTg0NWUtMmQzNDZhYWUxZmIyXkEyXkFqcGdeQXVyODE5NzE3OTE@._V1_.jpg", season: nil, episode: nil, profile: nil),
//     Post(postID: "", title: "Spenser Confidential", timeAgo: "5", previewImage: "https://m.media-amazon.com/images/M/MV5BMTdkOTEwYjMtNDA1YS00YzVlLTg0NWUtMmQzNDZhYWUxZmIyXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg", season: nil, episode: nil, profile: nil),
//     Post(postID: "",title: "The Tinder Swindler", timeAgo: "3", previewImage: "https://m.media-amazon.com/images/M/MV5BMTkwMTg2YWYtOGU5MS00YTdhLTg4N2QtYzcyZDE0MTlmNDU3XkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_.jpg", season: nil, episode: nil, profile: nil)
//         ]