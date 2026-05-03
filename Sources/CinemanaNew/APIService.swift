import Foundation

// MARK: - Real endpoints extracted from Cinemana binary
enum API {
    static let base        = "https://cinemana.shabakaty.com/api/android"
    static let infoBase    = "https://cinemana.shabakaty.com/api/info"
    static let account     = "https://account.shabakaty.com"
    static let recommend   = "https://recommend.shabakaty.com/api/recommendation/recommend"
    static let updates     = "https://updates.shabakaty.com/api/apps/3"

    // Auth paths (relative to account)
    static let registration      = "/api/registration"
    static let accountPicture    = "/api/account/picture"
    static let forgotPassword    = "/api/password/mobile-forgot-password"
    static let resetPassword     = "/api/password/mobile-reset"
    static let deviceEndpoint    = "/core/api/device"
}

enum APIError: LocalizedError {
    case invalidURL, noData, http(Int), decoding(Error), network(Error)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data"
        case .http(let c): return "HTTP \(c)"
        case .decoding(let e): return "Decode: \(e.localizedDescription)"
        case .network(let e): return e.localizedDescription
        }
    }
}

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()

    @Published var authToken: String? {
        didSet { UserDefaults.standard.set(authToken, forKey: "token") }
    }
    @Published var isLoggedIn = false
    @Published var userInfo: UserInfo?

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    private init() {
        authToken = UserDefaults.standard.string(forKey: "token")
        isLoggedIn = authToken != nil
    }

    // MARK: - Generic GET
    private func get<T: Decodable>(_ urlString: String, auth: Bool = false) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Cinemana/4.0 iOS", forHTTPHeaderField: "User-Agent")
        if auth, let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, resp) = try await session.data(for: req)
            if let h = resp as? HTTPURLResponse, !(200...299).contains(h.statusCode) {
                throw APIError.http(h.statusCode)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                // Try wrapping in array if single object expected
                throw APIError.decoding(error)
            }
        } catch let e as APIError { throw e }
        catch { throw APIError.network(error) }
    }

    // MARK: - Generic POST (form)
    private func post<T: Decodable>(_ urlString: String, body: [String: String]) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = body.map { "\($0.key)=\($0.value.urlEncoded)" }.joined(separator: "&").data(using: .utf8)
        do {
            let (data, resp) = try await session.data(for: req)
            if let h = resp as? HTTPURLResponse, !(200...299).contains(h.statusCode) {
                throw APIError.http(h.statusCode)
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let e as APIError { throw e }
        catch { throw APIError.network(error) }
    }

    // MARK: - HOME
    func fetchBanners(level: Int = 0) async throws -> [Banner] {
        return try await get("\(API.base)/banner/level/\(level)")
    }

    func fetchVideoGroups(lang: String = "ar") async throws -> [VideoGroup] {
        return try await get("\(API.base)/videoGroups/lang/\(lang)")
    }

    func fetchNewlyVideos(level: Int = 0, offset: Int = 0) async throws -> [Video] {
        return try await get("\(API.base)/newlyVideosItems/level/\(level)/offset/\(offset)")
    }

    func fetchHighlightEpisode() async throws -> [Video] {
        return try await get("\(API.base)/highlightEpisode")
    }

    // MARK: - COLLECTIONS
    func fetchCollectionsId() async throws -> [String] {
        return try await get("\(API.base)/collectionsId")
    }

    func fetchCollection(id: String) async throws -> VideoGroup {
        return try await get("\(API.base)/getCollection/collectionID/\(id)")
    }

    func fetchCollectionVideos(id: String) async throws -> [Video] {
        return try await get("\(API.base)/collectionVideos/collectionID/\(id)")
    }

    func fetchVideoListPagination(groupId: String) async throws -> [Video] {
        return try await get("\(API.base)/videoListPagination/groupID/\(groupId)")
    }

    // MARK: - SEARCH
    func search(query: String, type: String = "all") async throws -> [Video] {
        let q = query.urlEncoded
        let url = "\(API.base)/AdvancedSearch?type=\(type)&videoTitle=\(q)&year=1900,2026"
        return try await get(url)
    }

    func fetchAvailableYears() async throws -> [String] {
        return try await get("\(API.base)/AvailableSearchYears")
    }

    func fetchCategories() async throws -> [CategoryItem] {
        return try await get("\(API.base)/categories")
    }

    func fetchCategory() async throws -> [CategoryItem] {
        return try await get("\(API.base)/category")
    }

    // MARK: - DETAILS
    func fetchVideoDetails(id: String) async throws -> VideoDetails {
        return try await get("\(API.base)/allVideoInfo/id/\(id)")
    }

    func fetchSeasons(id: String) async throws -> [Season] {
        return try await get("\(API.base)/videoSeason/id/\(id)")
    }

    func fetchActor(id: String) async throws -> CastMember {
        return try await get("\(API.base)/staff/actorID/\(id)")
    }

    // MARK: - WATCH
    func fetchStreamFiles(id: String) async throws -> [StreamFile] {
        return try await get("\(API.base)/transcoddedFiles/id/\(id)")
    }

    func fetchSubtitles(id: String) async throws -> [SubtitleFile] {
        return try await get("\(API.base)/translationFiles/id/\(id)")
    }

    func checkVideoStatus(id: String) async throws -> [String: String] {
        return try await get("\(API.base)/memberCheckVideoStatus/id/\(id)", auth: true)
    }

    func checkParentalLevel(id: String) async throws -> [String: String] {
        return try await get("\(API.base)/checkVideoParentalLevel/\(id)")
    }

    // MARK: - USER
    func fetchUserInfo() async throws -> UserInfo {
        return try await get("\(API.infoBase)/userInfo", auth: true)
    }

    func fetchUserSettings(lang: String = "ar") async throws -> [String: String] {
        return try await get("\(API.base)/userSettings/lang/\(lang)", auth: true)
    }

    func fetchHistory(level: Int = 0) async throws -> [Video] {
        return try await get("\(API.base)/history/level/\(level)", auth: true)
    }

    func addToHistory(id: String) async {
        _ = try? await get("\(API.base)/addToHistory/\(id)", auth: true) as [String: String]
    }

    func addLike(id: String) async {
        _ = try? await get("\(API.base)/addLike/\(id)", auth: true) as [String: String]
    }

    func removeFromHistory(id: String) async {
        _ = try? await get("\(API.base)/removeFromHistory/\(id)", auth: true) as [String: String]
    }

    func removeAllHistory() async {
        _ = try? await get("\(API.base)/removeAllWatchHistory/", auth: true) as [String: String]
    }

    func fetchSubStatus() async throws -> [String: String] {
        return try await get("\(API.base)/get_subscription_status/", auth: true)
    }

    func fetchTranslationSettings() async throws -> [String: String] {
        return try await get("\(API.base)/UserTranslationSettings", auth: true)
    }

    // MARK: - NOTIFICATIONS
    func fetchNotifications() async throws -> [String: String] {
        return try await get("\(API.base)/get_notifications/", auth: true)
    }

    func setNotificationsViewed(id: String) async {
        _ = try? await get("\(API.base)/set_notifications_viewed/\(id)", auth: true) as [String: String]
    }

    func removeNotifications() async {
        _ = try? await get("\(API.base)/removeNotifications", auth: true) as [String: String]
    }

    // MARK: - RECOMMEND
    func fetchRecommendations(movieId: String, movieName: String) async throws -> [Video] {
        let name = movieName.urlEncoded
        let url = "\(API.recommend)?MovieId=\(movieId)&MovieName=\(name)&ReProcessIfExpired=true"
        return try await get(url)
    }

    // MARK: - AUTH (account.shabakaty.com)
    func login(email: String, password: String) async throws {
        let url = "\(API.account)/connect/token"
        let body = [
            "grant_type": "password",
            "client_id": "cinemana-mobile",
            "username": email,
            "password": password,
            "scope": "openid profile email offline_access"
        ]
        let resp: AuthResponse = try await post(url, body: body)
        if let token = resp.accessToken {
            self.authToken = token
            self.isLoggedIn = true
            Task { userInfo = try? await fetchUserInfo() }
        } else {
            throw APIError.noData
        }
    }

    func register(name: String, email: String, password: String) async throws {
        let url = "\(API.account)\(API.registration)"
        let body = ["name": name, "email": email, "password": password]
        let _: AuthResponse = try await post(url, body: body)
    }

    func logout() {
        authToken = nil
        isLoggedIn = false
        userInfo = nil
    }
}

// MARK: - String helper
extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
