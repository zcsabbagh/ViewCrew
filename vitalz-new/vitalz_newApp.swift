//
//  vitalz_newApp.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/9/24.
//

import SwiftUI

@main
struct vitalz_newApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
