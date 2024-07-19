//
//  AppIntent.swift
//  StocksWidget2
//
//  Created by Zane Sabbagh on 7/18/24.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    @Parameter(title: "Friends", default: .all)
    var selectedFriend: FriendOption

    static var parameterSummary: some ParameterSummary {
        Summary("Show streaming history for \(\.$selectedFriend)")
    }
}

enum FriendOption: String, CaseIterable, AppEnum {
    case all = "All"
    case zane = "Zane"
    case mira = "Mira"
    case ammar = "Ammar"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Friend"
    static var caseDisplayRepresentations: [FriendOption : DisplayRepresentation] = [
        .all: "All",
        .zane: "Zane",
        .mira: "Mira",
        .ammar: "Ammar"
    ]
}

