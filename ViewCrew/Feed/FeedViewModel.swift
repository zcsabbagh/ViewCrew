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
import AmplitudeSwift

class FeedViewModel: ObservableObject {
    @Published var posts: [PostType] = []
    @Published var isLoading: Bool = false
    private let db = Firestore.firestore()
    @Published var friends: [String]
    private var lastDocument: DocumentSnapshot?

    let amplitude = Amplitude(configuration: Configuration(
        apiKey: "f8da5e324708d7407ecad7b329e154c4"
    ))
    

    init(friends: [String] = []) {
        self.friends = friends
        fetchProfilePosts()
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
        if feedFriends.isEmpty {
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
            var fetchedPosts: [PostType] = []

            querySnapshot?.documents.forEach { document in
                self.processDocument(document, group: group) { posts in
                    fetchedPosts.append(contentsOf: posts)
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

    func extractPostIDs(completion: @escaping ([String]) -> Void) {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
        print("exiting extractPostIDs")
        completion([])
        return
        }
        
        db.collection("users").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
            print("Found user's doc in extractPostIDs")
                if let feed = document.data()?["feed"] as? [String] {
                    completion(feed)
                } else {
                    completion([])
                }
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
            }
        }
    }


    func fetchProfilePosts() {
        print("Entering fetchProfilePosts")
        extractPostIDs { postIDs in
            print("postIDs: \(postIDs)")
            guard !postIDs.isEmpty else {
                print("No post IDs to fetch")
                return
            }
            
            let batchSize = 10
            let batches = stride(from: 0, to: postIDs.count, by: batchSize).map {
                Array(postIDs[$0..<min($0 + batchSize, postIDs.count)])
            }
            
            let group = DispatchGroup()
            var allFetchedPosts: [PostType] = []
            
            for postID in postIDs {
                group.enter()
                self.db.collection("watchHistory").document(postID).getDocument { (document, error) in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error fetching document: \(error)")
                        return
                    }
                    
                    guard let document = document, document.exists else {
                        print("Document does not exist")
                        return
                    }
                    
                    self.processDocument(document, group: group) { posts in
                        allFetchedPosts.append(contentsOf: posts)
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.posts.append(contentsOf: allFetchedPosts)
                print("Fetched \(allFetchedPosts.count) profile posts")
            }

        }
    }



    private func processDocument(_ document: DocumentSnapshot, group: DispatchGroup, fetchedPosts: @escaping ([PostType]) -> Void) {
        print("Processing document \(document.documentID)")
        guard let data = document.data() else {
            print("Document data was empty.")
            return
        }
        
        // Extract relevant fields
        let title = data["videoTitle"] as? String ?? ""
        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        let imageURL = data["image"] as? String
        let season = data["season"] as? String
        let episode = data["episode"] as? String
        let seriesTitle = data["seriesTitle"] as? String
        let userId = data["userId"] as? String ?? ""
        let dateMilliseconds = data["date"] as? Double ?? 0
        let date = Date(timeIntervalSince1970: dateMilliseconds / 1000.0)
        let bookmark = data["bookmark"] as? Int ?? 0
        let post_type = data["post_type"] as? String ?? ""

        /* additional params for the different post types */
        let years_ago = data["years_ago"] as? Int
        let matchedUsers = data["matchedUsers"] as? [String]
        let percentageWatched = data["percentageWatched"] as? Int
        let numberEpisodes = data["numberEpisodes"] as? Int

        let postID = document.documentID

        // Only add post if it has an image
        if let imageURL = imageURL {
            print("Image URL found for document \(document.documentID)")
            group.enter()
            self.fetchProfile(for: userId) { profile in
                defer { group.leave() } // Ensure group.leave() is called
                print("Fetched profile for userId \(userId)")
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
                    profile: profile,
                    post_type: post_type,
                    years_ago: years_ago,
                    matchedUsers: matchedUsers,
                    percentageWatched: percentageWatched,
                    numberEpisodes: numberEpisodes
                )
                var localFetchedPosts = [PostType]()
                switch post_type {
                case "repeated_show":
                    localFetchedPosts.append(.Repeated(post))
                case "app_trending":
                    localFetchedPosts.append(.Trending(post))
                case "throwback":
                    localFetchedPosts.append(.Throwback(post))
                case "liked":
                    localFetchedPosts.append(.Liked(post))
                case "not_liked":
                    localFetchedPosts.append(.NotLiked(post))
                case "match":
                    localFetchedPosts.append(.Twins(post))
                case nil, "", "default":
                    localFetchedPosts.append(.Default(post))
                default:
                    localFetchedPosts.append(.Default(post))
                }
                fetchedPosts(localFetchedPosts)
            }
        } else {
            print("Couldn't find image for \(title)")
        }
    }

    private func fetchProfile(for userId: String, completion: @escaping (Profile?) -> Void) {
        guard !userId.isEmpty && userId != "test" && userId  != "" else {
            print("User ID is empty")
            completion(nil)
            return
        }
        
        print("Fetching profile for userId \(userId)")
        let usersCollection = db.collection("users")
        
        usersCollection.document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                print("Profile document found for userId \(userId)")
                let data = document.data()
                let username = data?["username"] as? String
                let name = data?["name"] as? String
                let profileImageURL = data?["profileImageURL"] as? String
                
                let profile = Profile(username: username, name: name, profileImage: profileImageURL)
                completion(profile)
            } else {
                print("Error fetching profile for userId \(userId): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    private func timeAgoSinceDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func addReaction(to documentID: String, emoji: String) {
        print("trying to add reaction to \(documentID) with emoji \(emoji)")
        let postsCollection = db.collection("watchHistory")
        let userId = UserDefaults.standard.string(forKey: "userID") ?? "test"

        amplitude.track(
            eventType: "Reaction Added",
            eventProperties: ["emoji": emoji, "documentID": documentID]
        )
        
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
