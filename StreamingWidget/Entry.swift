//
//  Entry.swift
//  StocksWidget2Extension
//
//  Created by Zane Sabbagh on 7/18/24.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let post: Post?
    let previewImageData: Data?
    let profileImageData: Data?
//    let user: Profile?
}
