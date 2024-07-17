//
//  FeedViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/16/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    private let db = Firestore.firestore()
    let friends = ["BYu4pymRieSFI567fZm5ZR6eh5c2"]

    init() {
        fetchRecentPosts(friends: friends)
    }
    
    func fetchRecentPosts(friends: [String]) {
        db.collection("watchHistory")
            .whereField("userId", in: friends)
            .order(by: "timestamp", descending: true)
            .limit(to: 30)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
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
                        self.posts = fetchedPosts
                    }
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
        let userId = Auth.auth().currentUser?.uid ?? ""
        
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
