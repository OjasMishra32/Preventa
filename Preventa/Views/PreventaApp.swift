//
//  PreventaApp.swift
//  Preventa
//
//  Created by Ojasva Mishra on 9/4/25.
//

import SwiftUI
import Firebase

@main
struct PreventaApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
