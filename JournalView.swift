import SwiftUII

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var mood: Int // 1..5
    var notes: String
}

final class JournalStore: ObservableObject {
    @Published var entries: [JournalEntry] = []
    
    private let key = "journal_entries"
    
    init() { load() }
    
    func add(mood: Int, notes: String) {
        let e = JournalEntry(id: UUID(), date: Date(), mood: mood, notes: notes)
        entries.insert(e, at: 0)
        save()
    }
    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            entries = arr
        }
    }
}

struct JournalView: View {
    @StateObject private var store = JournalStore()
    @State private var mood: Int = 3
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Check‑In").font(.headline)
                    Picker("Mood", selection: $mood) {
                        ForEach(1...5, id: \.(self)) { v in Text("\(v)") }
                    }.pickerStyle(.segmented)
                    TextEditor(text: $notes).frame(height: 100).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    Button("Save Entry") {
                        store.add(mood: mood, notes: notes)
                        notes = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                .background(Color.peakCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                List(store.entries) { e in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(e.date.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            Text("Mood: \(e.mood)")
                        }.font(.subheadline).foregroundColor(.secondary)
                        Text(e.notes)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding()
            .navigationTitle("Journal")
            .background(Color.peakBG.ignoresSafeArea())
        }
    }
}
