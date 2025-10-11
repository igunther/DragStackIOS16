import SwiftUI

struct TodoItemEditSheet: View {
    let originalItem: Item
    let onSave: (Item) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var emoji: String
    
    init(
        item: Item,
        onSave: @escaping (Item) -> Void
    ) {
        self.originalItem = item
        self.onSave = onSave
        self._title = State(initialValue: item.title)
        self._emoji = State(initialValue: item.emoji)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Todo Item Details") {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        TextField("Emoji", text: $emoji)
                            .font(.system(size: 28))
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Title")
                        Spacer()
                        TextField("Item title", text: $title)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedItem = Item(
                            id: originalItem.id,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(updatedItem)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    TodoItemEditSheet(
        item: Item(
            title: "Edit Video",
            emoji: "🎬"
        )
    ) { updatedItem in
        print("Updated: \(updatedItem)")
    }
}
