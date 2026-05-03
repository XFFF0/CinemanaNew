import Foundation

@MainActor
class WatchLaterManager: ObservableObject {
    static let shared = WatchLaterManager()
    @Published var items: [WatchLaterItem] = []
    private let key = "watch_later_v2"
    private init() { load() }

    func toggle(_ video: Video) {
        if contains(video.id) { remove(video.id) } else { add(video) }
    }
    func add(_ video: Video) {
        guard !contains(video.id) else { return }
        items.insert(WatchLaterItem(
            id: UUID().uuidString, videoId: video.id,
            title: video.displayTitle, posterURL: video.poster,
            type: video.type, year: video.year, addedAt: Date()
        ), at: 0)
        save()
    }
    func remove(_ videoId: String) {
        items.removeAll { $0.videoId == videoId }
        save()
    }
    func contains(_ videoId: String) -> Bool { items.contains { $0.videoId == videoId } }
    private func save() {
        if let d = try? JSONEncoder().encode(items) { UserDefaults.standard.set(d, forKey: key) }
    }
    private func load() {
        if let d = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode([WatchLaterItem].self, from: d) { items = s }
    }
}
