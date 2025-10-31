//
//  EDroneApp.swift
//  EDrone
//
//  Created by pawan on 29/10/25.
//

import SwiftUI

@main
struct EDroneApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
