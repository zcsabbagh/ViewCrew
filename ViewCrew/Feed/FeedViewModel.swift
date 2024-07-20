//
//  FeedViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/16/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    private let db = Firestore.firestore()
    @Published var friends: [String]
    private var lastDocument: DocumentSnapshot?

    init(friends: [String] = []) {
        self.friends = friends
        fetchRecentPosts()
    }
    
    func updateFriends(_ newFriends: [String]) {
        self.friends = newFriends
        fetchRecentPosts()
    }
    
    
    func refreshPosts() {
        isLoading = true
        lastDocument = nil
        fetchRecentPosts()
    }

    func loadMorePosts() {
        guard !isLoading else { return }
        isLoading = true
        fetchRecentPosts(loadMore: true)
    }

    func fetchRecentPosts(loadMore: Bool = false) {

        var feedFriends = friends
        if feedFriends.count == 0 {
            feedFriends = [UserDefaults.standard.string(forKey: "userID") ?? "test", "BYu4pymRieSFI567fZm5ZR6eh5c2"]
        }
        var query = db.collection("watchHistory")
            .whereField("userId", in: feedFriends)
            .order(by: "date", descending: true)
            .limit(to: 10)

        if loadMore, let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error getting documents: \(error)")
                self.isLoading = false
                return
            }

            let group = DispatchGroup()
            var fetchedPosts: [Post] = []
            
            querySnapshot?.documents.forEach { document in
                let data = document.data()
                
                // Extract relevant fields
                let title = data["videoTitle"] as? String ?? ""
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let imageURL = data["image"] as? String
                let season = data["season"] as? String
                let episode = data["episode"] as? String
                let seriesTitle = data["seriesTitle"] as? String
                let userId = data["userId"] as? String ?? ""
                let dateSeconds = data["date"] as? Double ?? 0
                let dateMilliseconds = data["date"] as? Double ?? 0
                let date = Date(timeIntervalSince1970: dateMilliseconds / 1000.0)
                let bookmark = data["bookmark"] as? Int ?? 0
                let postID = document.documentID
                
                // Only add post if it has an image
                if let imageURL = imageURL {
                    group.enter()
                    self.fetchProfile(for: userId) { profile in
                        let post = Post(
                            postID: postID,
                            title: title,
                            seriesTitle: seriesTitle,
                            timeAgo: self.timeAgoSinceDate(timestamp),
                            previewImage: imageURL,
                            season: season,
                            episode: episode,
                            date: self.timeAgoSinceDate(date),
                            bookmark: bookmark,
                            profileImageURL: nil,
                           
                            profile: profile
                            
                        )
                        fetchedPosts.append(post)
                        group.leave()
                    }
                } else {
                    print("Couldn't find image for \(title)")
                }
            }
            
            group.notify(queue: .main) {
                if loadMore {
                    self.posts.append(contentsOf: fetchedPosts)
                } else {
                    self.posts = fetchedPosts
                }
                self.lastDocument = querySnapshot?.documents.last
                self.isLoading = false
            }
        }
    }
    
    private func timeAgoSinceDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func fetchProfile(for userId: String, completion: @escaping (Profile?) -> Void) {
        let usersCollection = db.collection("users")
        
        usersCollection.document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let username = data?["username"] as? String
                let name = data?["name"] as? String
                let profileImageURL = data?["profileImageURL"] as? String
                
                let profile = Profile(username: username, name: name, profileImage: profileImageURL)
                        completion(profile)
            } else {
                completion(nil)
            }
        }
    }

    func addReaction(to documentID: String, emoji: String) {
        print("trying to add reaction to \(documentID) with emoji \(emoji)")
        let postsCollection = db.collection("watchHistory")
        let userId = UserDefaults.standard.string(forKey: "userID") ?? "test"
        
        postsCollection.document(documentID).getDocument { (document, error) in
            if let document = document, document.exists {
                var reactions = document.data()?["reactions"] as? [[String: String]] ?? []
                
                if let index = reactions.firstIndex(where: { $0["userId"] == userId }) {
                    reactions[index]["emoji"] = emoji
                } else {
                    reactions.append(["userId": userId, "emoji": emoji])
                }
                
                postsCollection.document(documentID).updateData([
                    "reactions": reactions
                ]) { error in
                    if let error = error {
                        print("Error adding reaction: \(error.localizedDescription)")
                    } else {
                        print("Reaction added successfully")
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}
