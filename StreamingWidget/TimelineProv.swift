//
//  TimelineProv.swift
//  StocksWidget2Extension
//
//  Created by Zane Sabbagh on 7/18/24.
//

import Intents
import WidgetKit
import SwiftUI

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
        
        if let previewImageURL = post.previewImage.flatMap({ URL(string: $0) }) {
            previewImageData = try? await fetchImageData(from: previewImageURL)
        }
        
        if let profileImageURL = post.profile?.profileImage.flatMap({ URL(string: $0) }) {
            profileImageData = try? await fetchImageData(from: profileImageURL)
        }
        
        return (post, previewImageData, profileImageData)
    }

    func fetchImageData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    func getPostData() async throws -> Post {
        let url = URL(string: "https://us-west1-candid2024-9f0fc.cloudfunctions.net/widgetFunction")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
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
            profile: postData.profile.map { Profile(username: $0.username, name: $0.name, profileImage: $0.profileImage) }
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
        let profile: ProfileResponse?
    }

    struct ProfileResponse: Codable {
        let username: String?
        let name: String?
        let profileImage: String?
    }
}

