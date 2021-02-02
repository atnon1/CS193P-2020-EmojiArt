//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Anton Makeev on 20.12.2020.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    //let store = EmojiArtDocumentStore(named: "Emoji Art")
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    //let store = EmojiArtDocumentStore(directory: url)
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(EmojiArtDocumentStore(directory: url))
        }
    }
}
