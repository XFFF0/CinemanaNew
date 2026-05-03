import Foundation
import Combine

@MainActor
class VideoDetailViewModel: ObservableObject {
    @Published var video: VideoModel
    @Published var episodes: [VideoModel] = []
    @Published var transcodeFiles: [TranscodeFile] = []
    @Published var translations: [TranslationInfo] = []
    @Published var recommendations: [VideoModel] = []

    @Published var isLoading: Bool = false
    @Published var isSubscribed: Bool = false

    @Published var selectedSeason: String = "1"
    @Published var seasons: [String] = []

    @Published var watchProgress: Double = 0
    @Published var isFavorite: Bool = false

    init(video: VideoModel) {
        self.video = video
    }

    func loadDetails() async {
        isLoading = true

        do {
            async let detailsTask = APIService.shared.getVideoDetails(videoId: video.nb)
            async let filesTask = APIService.shared.getTranscodedFiles(videoId: video.nb)
            async let translationsTask = APIService.shared.getTranslationFiles(videoId: video.nb)
            async let recsTask = APIService.shared.getRecommendations(movieId: video.nb)

            let (details, files, trans, recs) = try await (detailsTask, filesTask, translationsTask, recsTask)

            self.video = details
            self.transcodeFiles = files
            self.translations = trans
            self.recommendations = recs

            if video.isSeries {
                await loadEpisodes()
            }

            if AuthManager.shared.isLoggedIn {
                await checkSubscription()
                await loadWatchProgress()
            }
        } catch {
            print("Error loading video details: \(error)")
        }

        isLoading = false
    }

    func loadEpisodes() async {
        do {
            let rootId = video.rootSeries ?? video.nb
            let episodes = try await APIService.shared.getSeriesEpisodes(rootEpisodeId: rootId)

            let uniqueSeasons = Set(episodes.compactMap { $0.season }).sorted()
            self.seasons = uniqueSeasons

            if selectedSeason.isEmpty, let firstSeason = uniqueSeasons.first {
                selectedSeason = firstSeason
            }

            self.episodes = episodes.filter { $0.season == selectedSeason }
        } catch {
            print("Error loading episodes: \(error)")
        }
    }

    func checkSubscription() async {
        do {
            let status = try await APIService.shared.getSubscriptionStatus(videoId: video.nb)
            self.isSubscribed = status.isSubscribed ?? false
        } catch {
            print("Error checking subscription: \(error)")
        }
    }

    func loadWatchProgress() async {
        do {
            let status = try await APIService.shared.checkVideoStatus(videoId: video.nb)
            if let total = status.totalDuration, total > 0,
               let current = status.currentPosition {
                self.watchProgress = Double(current) / Double(total)
            }
        } catch {
            print("Error loading watch progress: \(error)")
        }
    }

    func toggleSubscription() async {
        do {
            if isSubscribed {
                try await APIService.shared.removeSubscription(videoId: video.nb)
            } else {
                try await APIService.shared.addSubscription(videoId: video.nb)
            }
            isSubscribed.toggle()
        } catch {
            print("Error toggling subscription: \(error)")
        }
    }

    func selectSeason(_ season: String) {
        selectedSeason = season
        episodes = episodes.filter { $0.season == season }
    }

    func addToHistory() async {
        guard AuthManager.shared.isLoggedIn else { return }

        do {
            try await APIService.shared.addToHistory(videoId: video.nb, kind: video.kind ?? "movie")
        } catch {
            print("Error adding to history: \(error)")
        }
    }

    func downloadVideo(_ video: VideoModel, quality: String) {
        guard let file = transcodeFiles.first(where: { $0.resolution == quality }) else {
            print("No file found for quality: \(quality)")
            return
        }
        
        DownloadManager.shared.startDownload(video: video, file: file)
    }

    func checkFavorite(_ video: VideoModel) -> Bool {
        return WatchLaterManager.shared.isInWatchLater(videoId: video.nb)
    }

    func toggleFavorite(_ video: VideoModel) {
        if isFavorite {
            WatchLaterManager.shared.removeFromWatchLater(videoId: video.nb)
        } else {
            WatchLaterManager.shared.addToWatchLater(video: video)
        }
        isFavorite.toggle()
    }
}