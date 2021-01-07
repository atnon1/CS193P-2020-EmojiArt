//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Anton Makeev on 20.12.2020.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    static let palette: String = "🍏🏀❤️🌅🐤🐵"
    
    @Published private var emojiArt: EmojiArt = EmojiArt() {
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    
    private static let untitled = "EmojiArtDocument.Untitled"
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    @Published var selectedEmojis = Set<EmojiArt.Emoji>()
    
    var aloneMovingEmoji: EmojiArt.Emoji?
    
    // MARK: -Intents
    
    // Returns `true` if `emoji` is selected
    func checkEmojiSelection(_ emoji: EmojiArt.Emoji)-> Bool {
        return selectedEmojis.contains(matching: emoji)
    }
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    public func moveSelectedEmojis(by offset: CGSize, withStartAt startEmoji: EmojiArt.Emoji? = nil) {
        if let movingEmoji = aloneMovingEmoji, let emoji = startEmoji {
            if movingEmoji.id == emoji.id {
                moveEmoji(emoji, by: offset)
                aloneMovingEmoji = nil
            }
        } else {
            for emoji in selectedEmojis {
                moveEmoji(emoji, by: offset)
            }
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    func scaleSelectedEmojis(by scale: CGFloat) {
        for emoji in selectedEmojis {
            scaleEmoji(emoji, by: scale)
        }
    }
    
    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    func selectEmoji(_ emoji: EmojiArt.Emoji) {
        if selectedEmojis.contains(matching: emoji) {
            selectedEmojis.remove(matching: emoji)
        } else {
            selectedEmojis.insert(emoji)
        }
    }
    
    func deleteEmoji(_ emoji: EmojiArt.Emoji) {
        emojiArt.deleteEmoji(emoji)
    }
    
    func tapImage() {
        selectedEmojis.removeAll()
    }
    
    //Checks if `emoji` moving alone
    func getMovingEmoji(_ emoji: EmojiArt.Emoji) {
        if !checkEmojiSelection(emoji) {
            aloneMovingEmoji = emoji
        }
    }
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
}

