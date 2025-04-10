//
//  MangaViewerAppApp.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-03-15.
//

import SwiftUI
import Firebase

@main
struct MangaViewerAppApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView() // Pour test uniquement
        }
    }
}
