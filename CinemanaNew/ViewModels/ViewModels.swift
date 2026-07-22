import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var banners: [Banner] = []
    @Published var newlyAdded: [VideoModel] = []
    @Published var groups: [VideoGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient.shared
    private let level = "1"

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let bannersTask = api.banners(level: level)
            async let newlyTask = api.newlyAdded(level: level)
            async let groupsTask = api.videoGroups(language: "ar", level: level)
            banners = try await bannersTask
            newlyAdded = try await newlyTask
            groups = try await groupsTask
        } catch {
            errorMessage = "تعذر تحميل الصفحة الرئيسية"
        }
        isLoading = false
    }
}

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var collections: [CollectionModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient.shared
    private let level = "1"

    func load() async {
        isLoading = true
        do {
            async let catTask = api.categories()
            async let colTask = api.collections(level: level)
            categories = try await catTask
            collections = try await colTask
        } catch {
            errorMessage = "تعذر تحميل التصنيفات"
        }
        isLoading = false
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [VideoModel] = []
    @Published var isLoading = false
    @Published var page = 1

    private let api = APIClient.shared

    func search() async {
        guard !query.isEmpty else { results = []; return }
        isLoading = true
        page = 1
        do {
            results = try await api.advancedSearch(title: query, page: page, level: "1")
        } catch {
            results = []
        }
        isLoading = false
    }

    func loadMore() async {
        page += 1
        do {
            let more = try await api.advancedSearch(title: query, page: page, level: "1")
            results.append(contentsOf: more)
        } catch {
            page -= 1
        }
    }
}

@MainActor
final class VideoDetailViewModel: ObservableObject {
    @Published var video: VideoModel?
    @Published var seasons: [VideoModel] = []
    @Published var comments: [VideoComment] = []
    @Published var transcodedFiles: [TranscodedFile] = []
    @Published var isLoading = false

    private let api = APIClient.shared

    func load(videoId: String) async {
        isLoading = true
        async let infoTask = api.videoInfo(id: videoId)
        async let commentsTask = api.comments(videoId: videoId)
        async let filesTask = api.transcodedFiles(id: videoId)

        video = try? await infoTask
        comments = (try? await commentsTask) ?? []
        transcodedFiles = (try? await filesTask) ?? []

        if let root = video?.rootSeries {
            seasons = (try? await api.videoSeasons(rootEpisodeId: root)) ?? []
        }
        isLoading = false
    }

    /// Best quality first, matching Android's "sort by size descending" behavior.
    var bestQuality: TranscodedFile? {
        transcodedFiles.max { ($0.size ?? 0) < ($1.size ?? 0) }
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var history: [VideoModel] = []
    @Published var isLoading = false

    private let api = APIClient.shared

    func loadHistory(userId: String) async {
        isLoading = true
        history = (try? await api.history(userId: userId, page: 1, kind: "movie")) ?? []
        isLoading = false
    }
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth = AuthService.shared

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.login(email: email, password: password)
        } catch {
            errorMessage = "فشل تسجيل الدخول — تأكد من البريد وكلمة المرور"
        }
        isLoading = false
    }
}
