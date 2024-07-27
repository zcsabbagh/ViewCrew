//
//  TimelineProv.swift
//  StocksWidget2Extension
//
//  Created by Zane Sabbagh on 7/18/24.
//

import Intents
import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let post: Post?
    let previewImageData: Data?
    let profileImageData: Data?
}


struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), post: nil, previewImageData: nil, profileImageData: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        do {
            let (post, previewImageData, profileImageData) = try await getPostDataAndImages()
            return SimpleEntry(date: Date(), configuration: configuration, post: post, previewImageData: previewImageData, profileImageData: profileImageData)
        } catch {
            print("Error fetching post data: \(error)")
            return SimpleEntry(date: Date(), configuration: configuration, post: nil, previewImageData: nil, profileImageData: nil)
        }
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        do {
            let (post, previewImageData, profileImageData) = try await getPostDataAndImages()
            let entry = SimpleEntry(date: Date(), configuration: configuration, post: post, previewImageData: previewImageData, profileImageData: profileImageData)
            return Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: 3600))) // Update every hour
        } catch {
            print("Error fetching post data: \(error)")
            let entry = SimpleEntry(date: Date(), configuration: configuration, post: nil, previewImageData: nil, profileImageData: nil)
            return Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: 3600)))
        }
    }

    func getPostDataAndImages() async throws -> (Post, Data?, Data?) {
        let post = try await getPostData()
        
        var previewImageData: Data? = nil
        var profileImageData: Data? = nil
        
//        if let previewImageURL = post.previewImage.flatMap({ URL(string: $0) }) {
//            previewImageData = getProfileImageFromSharedContainer(for: previewImageURL.absoluteString)
//        }
        
        if let profileImageURL = post.profileImageURL.flatMap({ URL(string: $0) }) {
            profileImageData = getProfileImageFromSharedContainer(for: profileImageURL.absoluteString)
        }
        
        
        // If the images aren't in the shared container, fetch them
        if previewImageData == nil, let previewImageURL = post.previewImage.flatMap({ URL(string: $0) }) {
            previewImageData = try? await fetchImageData(from: previewImageURL)
        }
        
//        if profileImageData == nil, let profileImageURL = post.profileImageURL.flatMap({ URL(string: $0) }) {
//            profileImageData = try? await fetchImageData(from: profileImageURL)
//        }

        print("Preview Image Data: \(previewImageData?.count ?? 0) bytes")
        print("Profile Image Data: \(profileImageData?.count ?? 0) bytes")
        
        return (post, previewImageData, profileImageData)
    }

    func getProfileImageFromSharedContainer(for imageURL: String) -> Data? {
        let filename = (imageURL as NSString).lastPathComponent
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.zane.ShareDefaults") else {
            print("Failed to get shared container URL")
            return nil
        }
        
        let fileURL = sharedContainer.appendingPathComponent(filename)
        
        return try? Data(contentsOf: fileURL)
    }

    func getFriends() -> [String] {
        let defaults = UserDefaults(suiteName: "group.zane.ShareDefaults")
        return defaults?.stringArray(forKey: "friendIDs") ?? []
    }

    func fetchImageData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        print("Fetched image data from \(url.absoluteString): \(data.count) bytes")
        return data
    }

    func getPostData() async throws -> Post {
        let url = URL(string: "https://us-central1-viewcrew-bc42a.cloudfunctions.net/widgetFunction")!
        
        var friends = getFriends()
        if let userID = UserDefaults(suiteName: "group.zane.ShareDefaults")?.string(forKey: "userID") {
            friends.append(userID)
        }
        
        let requestBody = ["friends": friends]
        // let requestBody = ["friends": ["otzDXhl6qScZFZWGQVBW"]]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let postData = try decoder.decode(PostResponse.self, from: data)
        
        return Post(
            postID: postData.postID,
            title: postData.title,
            seriesTitle: postData.seriesTitle,
            timeAgo: postData.timeAgo,
            previewImage: postData.previewImage,
            season: postData.season,
            episode: postData.episode,
            date: postData.date,
            bookmark: postData.bookmark,
            profileImageURL: postData.profileImageURL,
            userId: nil,
            profile: postData.profile.map { Profile(username: $0.username, name: $0.name, profileImage: $0.profileImage) },
            post_type: "default",
            years_ago: nil,
            matchedUsers: nil,
            percentageWatched: nil,
            numberEpisodes: nil
        )
    }

    struct PostResponse: Codable {
        let postID: String
        let title: String
        let seriesTitle: String?
        let timeAgo: String
        let previewImage: String?
        let season: String?
        let episode: String?
        let date: String?
        let bookmark: Int?
        let profileImageURL: String?
        let profile: ProfileResponse?
    }

    struct ProfileResponse: Codable {
        let username: String?
        let name: String?
        let profileImage: String?
    }
}
