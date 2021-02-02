//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Anton Makeev on 20.12.2020.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    
    
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    
    let id: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let palette: String = "🍏🏀❤️🌅🐤🐵"
    
    @Published private var emojiArt: EmojiArt = EmojiArt() {
        didSet {
            print("\(emojiArt.json?.utf8 ?? "nil")")
            save(emojiArt)
        }
    }
    
    var url: URL? {
        didSet { save(emojiArt) }
    }
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    init(url: URL) {
        id = UUID()
        self.url = url
        emojiArt = EmojiArt(json: (try? Data(contentsOf: url))) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    private func save(_ emojiArt: EmojiArt) {
        if let url = url {
            try? emojiArt.json?.write(to: url)
        } else {
            UserDefaults.standard.set(emojiArt.json, forKey: "EmojiArtDocument.\(self.id.uuidString)")
        }
    }
    
    
    @Published private(set) var backgroundImage: UIImage?
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published var steadyStateZoomScale: CGFloat = 1.0
    
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
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
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
    
    private var fetchImageCancellable: AnyCancellable?
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL?.imageURL {
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared
                .dataTaskPublisher(for: url)
                .map { data, urlResponse in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \.backgroundImage, on: self)
        }
    }
}

