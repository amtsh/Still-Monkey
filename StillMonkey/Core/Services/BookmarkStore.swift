//
//  BookmarkStore.swift
//  Still Monkey
//

import Foundation
import Observation

private struct BookmarkEnvelope: Codable {
    var version: Int
    var items: [BookmarkEntry]
}

@Observable
@MainActor
final class BookmarkStore {
    private static let userDefaultsKey = "stillMonkey.bookmarks.v2"
    private static let maxBookmarks = 100

    private let userDefaults: UserDefaults

    private(set) var entries: [BookmarkEntry] = []

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        entries = Self.load(from: userDefaults)
    }

    func refresh() {
        entries = Self.load(from: userDefaults)
    }

    func contains(stableKey: String) -> Bool {
        entries.contains { $0.stableKey == stableKey }
    }

    func addOrReplace(_ entry: BookmarkEntry) {
        var next = entries.filter { $0.stableKey != entry.stableKey }
        next.insert(entry, at: 0)
        if next.count > Self.maxBookmarks {
            next = Array(next.prefix(Self.maxBookmarks))
        }
        entries = next
        persist()
    }

    func remove(id: BookmarkEntry.ID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func remove(stableKey: String) {
        entries.removeAll { $0.stableKey == stableKey }
        persist()
    }

    func toggle(_ entry: BookmarkEntry) {
        if contains(stableKey: entry.stableKey) {
            remove(stableKey: entry.stableKey)
        } else {
            addOrReplace(entry)
        }
    }

    private func persist() {
        let envelope = BookmarkEnvelope(version: 2, items: entries)
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        userDefaults.set(data, forKey: Self.userDefaultsKey)
    }

    private static func load(from defaults: UserDefaults) -> [BookmarkEntry] {
        guard let data = defaults.data(forKey: userDefaultsKey) else { return [] }
        guard let envelope = try? JSONDecoder().decode(BookmarkEnvelope.self, from: data) else { return [] }
        return envelope.items.sorted { $0.addedAt > $1.addedAt }
    }
}
