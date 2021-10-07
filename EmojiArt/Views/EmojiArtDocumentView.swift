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
    @State var chosenPalette: String = ""
    
    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(chosenPalette.map {String($0)}, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiFontSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
            }
            .onAppear { chosenPalette = document.defaultPalette }
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
                    if isLoading {
                        Image(systemName: "hourglass")
                            .imageScale(.large)
                            .spinning()
                    } else {
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
                .onReceive(document.$backgroundImage) { image in
                    zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) {providers, location in
                    var location = location
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(leading: pickImage, trailing: Button( action: {
                    if let url = UIPasteboard.general.url, url != document.backgroundURL {
                        confirmBackgroundPaste = true
                    } else {
                        explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard").imageScale(.large)
                        .alert(isPresented: $explainBackgroundPaste) {
                               Alert(
                                title: Text("Paste background"),
                                message: Text("Copy the URL of an image and use this button to make it background of your document"),
                                dismissButton: .default(Text("OK")))
                        }
                }
                ))
            }
            .zIndex(-1)

            }
        .alert(isPresented: $confirmBackgroundPaste) {
            Alert(
                title: Text("Paste Background"),
                message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                primaryButton: .default(Text("OK")) {
                    document.backgroundURL = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    @State private var showImagePicker = false
    @State private var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
    
    private var pickImage: some View {
        HStack{
            Image(systemName: "photo").imageScale(.large).foregroundColor(.accentColor).onTapGesture {
                imagePickerSourceType = .photoLibrary
                DispatchQueue.main.async {
                    showImagePicker = true
                }
            }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Image(systemName: "camera").imageScale(.large).foregroundColor(.accentColor).onTapGesture {
                    imagePickerSourceType = .camera
                    DispatchQueue.main.async {
                        showImagePicker = true
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { image in
                if image != nil {
                    DispatchQueue.main.async {
                        document.backgroundURL = image!.storeInFilesystem()
                    }
                }
                showImagePicker = false
            }
        }
    }
    
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    @State private var deleteButtonIsActive = false
    @GestureState private var gestureLongPresure = false
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var emojiGestureZoomScale: CGFloat = 1.0
    
    private var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    private var zoomScale: CGFloat {
        document.steadyStateZoomScale * gestureZoomScale
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
                document.steadyStateZoomScale *= finalGestureScale
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
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    //@State private var emojidocument.steadyStatePanOffset: CGSize = .zero
    @GestureState private var emojiGesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private var emojiPanOffset: CGSize {
        (emojiGesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        if document.selectedEmojis.isEmpty {
            return DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureView in
                document.steadyStatePanOffset = document.steadyStatePanOffset + (finalDragGestureView.translation / zoomScale)
            }
        } else {
            //Moving selected emojis
            var locationOffset = CGSize.zero
            return DragGesture()
                .updating($emojiGesturePanOffset) { latestDragGestureValue, emojiGesturePanOffset, _ in
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
            .updating($emojiGesturePanOffset) { latestDragGestureValue, emojiGesturePanOffset, _ in
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
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            document.steadyStatePanOffset = .zero
            document.steadyStateZoomScale = min(hZoom, vZoom)
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
        location = CGPoint(x: location.x + deleteButtonOffset * emojiZoomScale(emoji) * CGFloat(emoji.fontSize), y: location.y - deleteButtonOffset * emojiZoomScale(emoji) * CGFloat(emoji.fontSize))
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                document.addEmoji(string, at: location, size: defaultEmojiFontSize)
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

    // MARK: - Constants
    
    private let defaultEmojiFontSize: CGFloat = 40.0
    private let selectedEmojiShadowRadius: CGFloat = 5
    private let deleteButtonOffset: CGFloat = 0.5
    
}
