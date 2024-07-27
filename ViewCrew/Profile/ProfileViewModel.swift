//
//  ProfileViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/11/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var profilePicture: String = ""
    @Published var lastWeekStats: [Int] = [351, 52, 4]
    @Published var genres: [String] = []
    @Published var recentWatches: [Post] = []

    @AppStorage("savedGenres") private var savedGenres: String = ""


    private let db = Firestore.firestore()

    init() {
        self.genres = savedGenres.split(separator: ",").map(String.init)
        fetchUserData()
        fetchRecentWatches()
        fetchUserStats()
        
    }

    func fetchUserStats() {
        let userId = UserDefaults.standard.string(forKey: "userID") ?? "test"
    
        // Calculate the start of the current week
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)
        let startOfWeekTimestamp = Int(startOfWeek.timeIntervalSince1970)
        
        db.collection("watchHistory")
        .whereField("userId", isEqualTo: userId)
        .whereField("date", isGreaterThanOrEqualTo: startOfWeekTimestamp)
        .getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                var moviesCount: Int = 0
                var seriesCount: Int = 0
                var totalWatchTime: Double = 0
                
                for document in querySnapshot!.documents {
                    let data = document.data()
                    
                    if data["seriesTitle"] == nil {
                        moviesCount += 1
                    } else {
                        seriesCount += 1
                    }
                    
                
                    
                    if let bookmark = data["bookmark"] as? Double {
                        totalWatchTime += bookmark
                    } else if let bookmark = data["bookmark"] as? Int {
                        totalWatchTime += Double(bookmark)
                    } else if let bookmark = data["bookmark"] as? String, let bookmarkDouble = Double(bookmark) {
                        totalWatchTime += bookmarkDouble
                    }
                    
                   
                }
                
                let watchTimeMins = Int(totalWatchTime / 60)
                
                DispatchQueue.main.async {
                    self.lastWeekStats = [watchTimeMins, seriesCount, moviesCount]
                    print("Last week stats: \(self.lastWeekStats)")
                }
            }
        }
    }


    func fetchUserData() {
        let userId = UserDefaults.standard.string(forKey: "userID") ?? "test"

        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                let data = document.data()
                
                DispatchQueue.main.async {
                    self.displayName = data?["displayName"] as? String ?? ""
                    self.username = data?["username"] as? String ?? ""
                    self.profilePicture = data?["profileImageURL"] as? String ?? ""
                }
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func fetchRecentWatches() {
        let userId = UserDefaults.standard.string(forKey: "userID") ?? "test"
        db.collection("watchHistory")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: 20)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    var recentWatches: [Post] = []
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        if let imageURL = data["image"] as? String, !imageURL.isEmpty {
                            let post = Post(
                                postID: document.documentID,
                                title: data["title"] as? String ?? "",
                                seriesTitle: data["seriesTitle"] as? String,
                                timeAgo: data["timeAgo"] as? String ?? "",
                                previewImage: imageURL,
                                season: data["season"] as? String,
                                episode: data["episode"] as? String,
                                date: data["date"] as? String ?? "",
                                bookmark: data["float"] as? Int ?? 0,
                                profileImageURL: nil,
                                userId: nil,
            
                               
                                profile: nil,
                                post_type: "",
                                years_ago: nil,
                                matchedUsers: nil,
                                percentageWatched: nil,
                                numberEpisodes: nil
                            )
                            recentWatches.append(post)
                        }
                    }
                        
                        
                    
                    DispatchQueue.main.async {
                        self.recentWatches = recentWatches
                        self.fetchMovieCategories()
                    }
                }
            }
    }

    func fetchMovieCategories() {
       
        let userId = UserDefaults.standard.string(forKey: "userID") ?? "test"

        guard let url = URL(string: "https://us-west1-candid2024-9f0fc.cloudfunctions.net/getMovieCategories") else {
            print("Invalid URL")
            return
        }

        // Create the movies string from recentWatches
        let movies = self.recentWatches.map { $0.seriesTitle ?? $0.title }.joined(separator: ",")

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create the request body
        let body: [String: String] = ["movies": movies]
        request.httpBody = try? JSONEncoder().encode(body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error making request: \(error)")
                return
            }

            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                print("Invalid response data")
                return
            }

            let categories = responseString.split(separator: ",").map { String($0) }
            
            DispatchQueue.main.async {
                self.genres = categories
                self.savedGenres = categories.joined(separator: ",")
            }
        }
        task.resume()
    }




}
