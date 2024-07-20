//
//  FeedDataModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/17/24.
//

import Foundation
import SwiftUI
import Combine

enum PostType: Hashable, Equatable {
    case Default(Post)
    case Repeated(Post, numEpisodes: String)
    case Twins(Post, twin: Profile)
    case Trending(Post, friends: [Profile])
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .Default(let post):
            hasher.combine(post)
        case .Repeated(let post, let numEpisodes):
            hasher.combine(post)
            hasher.combine(numEpisodes)
        case .Twins(let post, let twin):
            hasher.combine(post)
            hasher.combine(twin)
        case .Trending(let post, let friends):
            hasher.combine(post)
            hasher.combine(friends)
        }
    }
    
    static func == (lhs: PostType, rhs: PostType) -> Bool {
        switch (lhs, rhs) {
        case (.Default(let post1), .Default(let post2)):
            return post1 == post2
        case (.Repeated(let post1, let num1), .Repeated(let post2, let num2)):
            return post1 == post2 && num1 == num2
        case (.Twins(let post1, let twin1), .Twins(let post2, let twin2)):
            return post1 == post2 && twin1 == twin2
        case (.Trending(let post1, let friends1), .Trending(let post2, let friends2)):
            return post1 == post2 && friends1 == friends2
        default:
            return false
        }
    }
}

struct Post: Identifiable, Hashable, Equatable {
    let id = UUID()
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
    let profile: Profile?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Profile: Identifiable, Equatable, Hashable {
    let id = UUID()
    let username: String?
    let name: String?
    let profileImage: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id
    }
}