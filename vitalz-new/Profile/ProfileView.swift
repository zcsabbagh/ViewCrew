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
            
            // Recently watched
            RecentlyWatched(posts: viewModel.recentWatches)
            
            // Last week statistics box
            LastWeek(stats: viewModel.lastWeekStats)
            
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
        HStack (spacing: 10) {
            AsyncImage(url: URL(string: viewModel.profilePicture)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 1)
            )
            
            VStack {
                Text(viewModel.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                Text(viewModel.username)
                    .foregroundColor(.gray)
                
            }
            .padding(.leading, 5)
            
        }
        .padding()
    }

}

struct RecentlyWatched: View {
    var posts: [Post]

    var body: some View {
        VStack (spacing: -13) {
            Text("recently watched")
                .font(.system(size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize * 1.3))
                .foregroundColor(Color.red.opacity(0.8))
                .fontWeight(.bold)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(posts, id: \.self) { post in
                        ProfileMovie(movie: post)
                    }
                }
                
            }
        }
        .padding()
    }
}


struct ProfileMovie: View {
    var movie: Post

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: movie.previewImage ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 200)
                    .background(Color.white)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.buttonBackground, lineWidth: 0.5)
                    )
            } placeholder: {
                ProgressView()
                    .frame(width: 150, height: 200)
                    .background(Color.white)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.buttonBackground, lineWidth: 0.5)
                    )
            }
        }
            
    }
}



struct LastWeek: View {
    var stats: [Int]

    var body: some View {
        VStack (spacing: 10) {
            Text("LAST WEEK")
                .font(.title2)
                .foregroundColor(.gray)
                .fontWeight(.bold)
            HStack {
                ProfileStatsBox(title: "min watched", value: stats[0])
                ProfileStatsBox(title: "episodes", value: stats[1])
                ProfileStatsBox(title: "movies", value: stats[2])
            }
        }
        .padding()
    }
}

struct ProfileStatsBox: View {
    var title: String
    var value: Int

    var body: some View {
        VStack (spacing: 0){
            Text("\(value)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: UIScreen.main.bounds.width / 5)
        .padding()
        .background(Color.buttonBackground)
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
//     Post(postID: "", title: "Pain Hustlers", timeAgo: "2", previewImage: "https://m.media-amazon.com/images/M/MV5BNWMxYjNhZmEtNDBjZi00ZjFmLWJlZDMtYTVlYjljMmNkZWFhXkEyXkFqcGdeQXVyODE5NzE3OTE@._V1_.jpg", season: nil, episode: nil, profile: nil),
//     Post(postID: "", title: "Spenser Confidential", timeAgo: "5", previewImage: "https://m.media-amazon.com/images/M/MV5BMTdkOTEwYjMtNDA1YS00YzVlLTg0NWUtMmQzNDZhYWUxZmIyXkEyXkFqcGdeQXVyMTkxNjUyNQ@@._V1_.jpg", season: nil, episode: nil, profile: nil),
//     Post(postID: "",title: "The Tinder Swindler", timeAgo: "3", previewImage: "https://m.media-amazon.com/images/M/MV5BMTkwMTg2YWYtOGU5MS00YTdhLTg4N2QtYzcyZDE0MTlmNDU3XkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_.jpg", season: nil, episode: nil, profile: nil)
//         ]

