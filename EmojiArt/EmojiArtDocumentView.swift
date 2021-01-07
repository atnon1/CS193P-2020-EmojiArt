//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Anton Makeev on 20.12.2020.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    
    var selectedEmojis = Set<EmojiArt.Emoji>()
    
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.palette.map {String($0)}, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: self.deafultEomojiFontSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)
            .layoutPriority(20)
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(
                        doubleTapToZoom(in: geometry.size)
                            .exclusively(before: singleTapGesture())
                    )
                    ForEach(self.document.emojis) { emoji in
                        ZStack {
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * emojiZoomScale(emoji))
                                .position(position(for: emoji, in: geometry.size))
                                .onTapGesture {
                                    document.selectEmoji(emoji)
                                    deleteButtonIsActive = false
                                }
                                .shadow(color: .black, radius: document.checkEmojiSelection(emoji) ? selectedEmojiShadowRadius : 0.0)
                                .shadow(color: .black, radius: document.checkEmojiSelection(emoji) ? selectedEmojiShadowRadius : 0.0)
                                .gesture(
                                    emojiPanGesture(emoji: emoji)
                                )
                            Button(action: {
                                document.deleteEmoji(emoji)
                                deleteButtonIsActive = false
                            }, label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                    .overlay(Circle().fill(Color.black))
                                    .overlay(Image(systemName: "xmark.circle.fill").foregroundColor(.red))
                            })
                            .disabled(!deleteButtonIsActive)
                            .opacity(deleteButtonIsActive ? 1 : 0)
                            .position(positionDeleteButton(for: emoji, in: geometry.size))
                        }
                    }
                }
                .clipped()
                .gesture(panGesture())
                .gesture(
                    zoomGesture()
                )
                .onLongPressGesture {
                    deleteButtonIsActive = !deleteButtonIsActive
                }
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) {providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                }
            }
            .layoutPriority(0)
        }
    }
    
    @State private var deleteButtonIsActive = false
    @GestureState private var gestureLongPresure = false
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var emojiGestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func emojiZoomScale(_ emoji: EmojiArt.Emoji) -> CGFloat {
        zoomScale * (document.checkEmojiSelection(emoji) ? emojiGestureZoomScale : 1.0)
    }
    
    private func zoomGesture() -> some Gesture {
        if document.selectedEmojis.isEmpty {
        return MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                steadyStateZoomScale *= finalGestureScale
            }
        } else {
            return MagnificationGesture()
                .updating($emojiGestureZoomScale) { latestGestureScale, emojiGestureZoomScale, _ in
                    emojiGestureZoomScale = latestGestureScale
                }
                .onEnded { finalGestureScale in
                    document.scaleSelectedEmojis(by: finalGestureScale)
                }
        }
    }
    
    private func doubleTapToZoom (in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                    deleteButtonIsActive = false
                }
        }
    }
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    //@State private var emojiSteadyStatePanOffset: CGSize = .zero
    @GestureState private var emojIGesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private var emojiPanOffset: CGSize {
        (emojIGesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        if document.selectedEmojis.isEmpty {
            return DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureView in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureView.translation / zoomScale)
            }
        } else {
            //Moving selected emojis
            var locationOffset = CGSize.zero
            return DragGesture()
                .updating($emojIGesturePanOffset) { latestDragGestureValue, emojiGesturePanOffset, _ in
                    emojiGesturePanOffset = latestDragGestureValue.translation / zoomScale
                }
                .onEnded { finalDragGestureView in
                    locationOffset = finalDragGestureView.translation / zoomScale
                    document.moveSelectedEmojis(by: locationOffset)
                }
        }
    }
    
    private func emojiPanGesture(emoji: EmojiArt.Emoji? = nil) -> some Gesture {
        var locationOffset = CGSize.zero
        let gesture = DragGesture()
            .updating($emojIGesturePanOffset) { latestDragGestureValue, emojiGesturePanOffset, _ in
                emojiGesturePanOffset = latestDragGestureValue.translation / zoomScale
                if let emoji = emoji {
                    document.getMovingEmoji(emoji)
                }
            }
            .onEnded { finalDragGestureView in
                locationOffset = finalDragGestureView.translation / zoomScale
                document.moveSelectedEmojis(by: locationOffset, withStartAt: emoji)
            }
        return gesture
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }

    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        var isSelected = document.checkEmojiSelection(emoji)
        if let aloneMovingEmoji = document.aloneMovingEmoji {
            isSelected = emoji.id == aloneMovingEmoji.id
        }
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2 )
        location = CGPoint(x: location.x + panOffset.width + (isSelected ? emojiPanOffset.width : 0), y: location.y + panOffset.height + (isSelected ? emojiPanOffset.height : 0))
        return location
    }
    
    private func positionDeleteButton(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = position(for: emoji, in: size)
        location = CGPoint(x: location.x + deleteButtonOffset * zoomScale, y: location.y - deleteButtonOffset * zoomScale)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.deafultEomojiFontSize)
            }
        }
        return found
    }
    
    private func singleTapGesture() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                withAnimation(.linear) {
                    document.tapImage()
                    deleteButtonIsActive = false
                }
            }
    }

    private let deafultEomojiFontSize: CGFloat = 40.0
    private let selectedEmojiShadowRadius: CGFloat = 5
    private let deleteButtonOffset: CGFloat = 15
    
}
