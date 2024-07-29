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
    case Repeated(Post)
    case Twins(Post)
    case Trending(Post)
    case Liked(Post)
    case NotLiked(Post)
    case Throwback(Post)
    
    var post: Post {
        switch self {
        case .Default(let post),
             .Repeated(let post),
             .Twins(let post),
             .Trending(let post),
             .Liked(let post),
             .NotLiked(let post),
             .Throwback(let post):
            return post
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .Default(let post),
             .Repeated(let post),
             .Twins(let post),
             .Trending(let post),
             .Liked(let post),
             .NotLiked(let post),
             .Throwback(let post):
            hasher.combine(post)
        }
    }
    
    static func == (lhs: PostType, rhs: PostType) -> Bool {
        switch (lhs, rhs) {
        case (.Default(let post1), .Default(let post2)),
             (.Repeated(let post1), .Repeated(let post2)),
             (.Twins(let post1), .Twins(let post2)),
             (.Trending(let post1), .Trending(let post2)),
             (.Liked(let post1), .Liked(let post2)),
             (.NotLiked(let post1), .NotLiked(let post2)),
             (.Throwback(let post1), .Throwback(let post2)):
            return post1 == post2
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
    let youtubeTrailerURL: String?
    let tomatoMeterScore: String?
    let imdbScore: String?
    let metacriticRating: String?
    let profileImageURL: String?
    let userId: String?
    let profile: Profile?
    let post_type: String

    // Additional parameters for different post types
    let years_ago: Int?
    let matchedUsers: [String]?
    let percentageWatched: Int?
    let numberEpisodes: Int?

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