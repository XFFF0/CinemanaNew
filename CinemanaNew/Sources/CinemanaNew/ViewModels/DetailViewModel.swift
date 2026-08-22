import Foundation

class DetailViewModel: ObservableObject {
    @Published var videoFiles:    [TranscodedFile] = []
    @Published var episodes:      [SeasonEpisode] = []
    @Published var comments:      [VideoComment] = []
    @Published var relatedVideos: [VideoItem] = []
    @Published var isLoading         = false
    @Published var isLoadingComments = false
    @Published var currentEpisodeID: String?

    private let api = NetworkService.shared

    func loadAll(video: VideoItem) {
        // For movies — load files directly
        if video.isMovie {
            loadFiles(videoId: video.id)
        }
        // For series — first load episodes, then auto-load first episode files
        if video.isSeries {
            loadEpisodes(rootId: video.id)
        }
        loadComments(videoId: video.id)

        // Related
        api.browseVideos(videoKind: video.isMovie ? 1 : 2, page: 1) { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let items) = r {
                    self?.relatedVideos = items.filter { $0.id != video.id }.prefix(10).map { $0 }
                }
            }
        }
    }

    func loadFiles(videoId: String) {
        isLoading = true
        currentEpisodeID = videoId
        api.transcoddedFiles(id: videoId) { [weak self] r in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let files) = r { self?.videoFiles = files }
            }
        }
    }

    func loadEpisodes(rootId: String) {
        api.videoSeason(id: rootId) { [weak self] r in
            DispatchQueue.main.async {
                if case .success(let eps) = r {
                    self?.episodes = eps
                    // Auto-load first episode files
                    if let first = eps.first {
                        self?.loadFiles(videoId: first.id)
                    }
                }
            }
        }
    }

    func loadComments(videoId: String) {
        isLoadingComments = true
        api.videoComments(id: videoId) { [weak self] r in
            DispatchQueue.main.async {
                self?.isLoadingComments = false
                if case .success(let c) = r { self?.comments = c }
            }
        }
    }

    func postComment(userId: String, videoId: String, text: String) {
        api.addComment(id: userId, videoId: videoId, comment: text) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.loadComments(videoId: videoId)
            }
        }
    }

    func addLike(userId: String, videoId: String, value: Int) {
        api.addLike(userId: userId, videoId: videoId, likeValue: value) { _ in }
    }

    func addToHistory(userId: String, videoId: String, kind: Int) {
        api.addToHistory(userId: userId, videoId: videoId, kind: kind) { _ in }
    }
}
