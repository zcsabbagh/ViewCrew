//
//  WidgetView.swift
//  StocksWidget2Extension
//
//  Created by Zane Sabbagh on 7/18/24.
//

import Foundation
import WidgetKit
import SwiftUI
import SDWebImageSwiftUI

struct StocksWidget2EntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let post = entry.post {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let seriesTitle = post.seriesTitle {
                    Text(seriesTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let imageData = entry.previewImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .cornerRadius(8)
                }
                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let profile = post.profile {
                    HStack {
                        if let profileImageData = entry.profileImageData, let uiImage = UIImage(data: profileImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }
                        Text(profile.name ?? profile.username ?? "Unknown")
                            .font(.caption)
                    }
                }
            }
            .padding()
        } else {
            Text("No data available")
                .padding()
        }
    }
}