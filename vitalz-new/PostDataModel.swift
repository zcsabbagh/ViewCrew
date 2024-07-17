//
//  FeedDataModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/17/24.
//

import Foundation
import SwiftUI
import Combine

struct Post: Identifiable, Hashable, Equatable {
    let id = UUID()
    let postID: String
    let title: String
    let seriesTitle: String?
    let timeAgo: String
    let previewImage: String?
    let season: String?
    let episode: String?
    
    let profile: Profile?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Profile: Identifiable, Equatable {
    let id = UUID()
    let username: String?
    let name: String?
    let profileImage: String?
    
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id
    }
}
