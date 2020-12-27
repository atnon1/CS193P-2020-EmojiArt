//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Anton Makeev on 27.12.2020.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
            }
        }
    }
}
