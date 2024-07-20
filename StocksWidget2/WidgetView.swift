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
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    private var scaleFactor: CGFloat {
        family == .systemLarge ? 2.0 : 1.0
    }

    var body: some View {
        if let post = entry.post {
            VStack(alignment: .leading, spacing: 2 * scaleFactor) {
                HStack {
                    seriesImage
                    VStack {
                        netflixIcon
                        profilePicture
                       
                    }
                }
                seriesTitle
            }
            .padding(10 * scaleFactor)
        } else {
            Text("Can't find any posts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var seriesImage: some View {
        Group {
            if let imageData = entry.previewImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90 * scaleFactor, height: 90 * scaleFactor)
                    .cornerRadius(8 * scaleFactor)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90 * scaleFactor, height: 90 * scaleFactor)
                    .foregroundColor(.gray)
            }
        }
    }

    private var profilePicture: some View {
        Group {
            if let profileImageData = entry.profileImageData, let uiImage = UIImage(data: profileImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30 * scaleFactor, height: 30 * scaleFactor)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 30 * scaleFactor, height: 30 * scaleFactor)
                    .foregroundColor(.gray)
            }
        }
    }

    private var netflixIcon: some View {
        Image("netflixWidgetIcon")
            .resizable()
            .frame(width: 30 * scaleFactor, height: 30 * scaleFactor)
            .clipShape(Circle())
    }

    private var seriesTitle: some View {

        VStack(alignment: .leading, spacing: -5) {
            
            if let seriesTitle = entry.post?.seriesTitle {
            
                Text(seriesTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .scaleEffect(scaleFactor)
                Text(entry.post?.title ?? "")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .scaleEffect(scaleFactor)

            } else {
                Text(entry.post?.title ?? "")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .scaleEffect(scaleFactor)
            }

        }
        .padding(.horizontal, 5 * scaleFactor)

    }
}
