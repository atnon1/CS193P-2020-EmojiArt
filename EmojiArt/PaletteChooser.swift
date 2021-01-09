//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Anton Makeev on 09.01.2021.
//

import SwiftUI

struct PaletteChooser: View {
    
    @ObservedObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    
    var body: some View {
        HStack {
            Stepper(
                onIncrement:  { chosenPalette = document.palette(after: chosenPalette) },
                onDecrement:  { chosenPalette = document.palette(before: chosenPalette) },
                label: {
                    EmptyView()
                })
            Text(document.paletteNames[chosenPalette] ?? "")
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
