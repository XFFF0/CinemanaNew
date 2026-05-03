import Foundation

@MainActor
class WatchLaterManager: ObservableObject {
    static let shared = WatchLaterManager()

    @Published var watchLaterItems: [WatchLaterItem] = []

    private let key = "com.shabakaty.cinemanaa.watchLater"

    private init() {
        loadWatchLater()
    }

    func addToWatchLater(_ video: VideoModel) {
        guard !isInWatchLater(videoId: video.nb) else { return }

        let item = WatchLaterItem(
            videoId: video.nb,
            title: video.title,
            thumbnailUrl: video.thumbnailUrl,
            kind: video.kind,
            addedAt: Date()
        )

        watchLaterItems.insert(item, at: 0)
        saveWatchLater()
    }

    func removeFromWatchLater(videoId: String) {
        watchLaterItems.removeAll { $0.videoId == videoId }
        saveWatchLater()
    }

    func removeFromWatchLater(_ item: WatchLaterItem) {
        removeFromWatchLater(videoId: item.videoId)
    }

    func isInWatchLater(videoId: String) -> Bool {
        watchLaterItems.contains { $0.videoId == videoId }
    }

    func toggleWatchLater(_ video: VideoModel) {
        if isInWatchLater(videoId: video.nb) {
            removeFromWatchLater(videoId: video.nb)
        } else {
            addToWatchLater(video)
        }
    }

    func clearWatchLater() {
        watchLaterItems.removeAll()
        saveWatchLater()
    }

    private func loadWatchLater() {
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([WatchLaterItem].self, from: data) {
            watchLaterItems = items
        }
    }

    private func saveWatchLater() {
        if let data = try? JSONEncoder().encode(watchLaterItems) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}