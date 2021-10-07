//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Anton Makeev on 12.01.2021.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    @State private var editMode: EditMode = .inactive
    @State private var notUniqueNameAlert = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink(destination: EmojiArtDocumentView(document: document)
                                    .navigationBarTitle(store.name(for: document))
                    ) {
                        EditableText(store.name(for: document), isEditing: editMode.isEditing) { name in
                            let isUnique = store.setName(name, for: document)
                            notUniqueNameAlert = !isUnique
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { store.documents[$0] }.forEach { document in
                        store.removeDocument(document)
                    }
                }
            }
            .navigationBarTitle(store.name)
            .navigationBarItems(leading:Button( action: {
                store.addDocument()
            }, label: {
                Image(systemName: "plus").imageScale(.large)
            }),
            trailing: EditButton()
            )
            .navigationViewStyle(StackNavigationViewStyle())
            .environment(\.editMode, $editMode)
            .alert(isPresented: $notUniqueNameAlert) {
            Alert(
                title: Text("Not unique name"),
                message: Text("Name is not unique. Change is not applied."),
                dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
