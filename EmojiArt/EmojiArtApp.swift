//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Anton Makeev on 20.12.2020.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let store = EmojiArtDocumentStore(named: "Emoji Art")
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
