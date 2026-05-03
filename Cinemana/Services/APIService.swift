import Foundation

class APIService {
    static let shared = APIService()

    private let baseURL = "https://cinemana.shabakaty.com/api/android/"
    private let identityBaseURL = "https://account.shabakaty.com/"
    private let recommendBaseURL = "https://recommend.shabakaty.com/api/recommendation/"

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    private func makeRequest<T: Decodable>(
        endpoint: String,
        baseURL: String = "",
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        let urlString = baseURL.isEmpty ? baseURL + endpoint : baseURL + endpoint

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        if requiresAuth {
            let token = AuthManager.shared.accessToken
            if !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let body = body {
            request.httpBody = body
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch is DecodingError {
            throw APIError.decodingError
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Home & Content

    func getHomeGroups(language: String = "en", parentalLevel: Int = 0) async throws -> [VideosGroup] {
        let response: HomeGroupsResponse = try await makeRequest(
            endpoint: "videoGroups/lang/\(language)/level/\(parentalLevel)"
        )
        return response.groups ?? []
    }

    func getNewlyVideos(parentalLevel: Int = 0, offset: Int = 12) async throws -> [VideoModel] {
        try await makeRequest(endpoint: "newlyVideosItems/level/\(parentalLevel)/offset/\(offset)/")
    }

    func getBanners(parentalLevel: Int = 0) async throws -> [VideoModel] {
        try await makeRequest(endpoint: "banner/level/\(parentalLevel)")
    }

    func getVideoDetails(videoId: String) async throws -> VideoModel {
        try await makeRequest(endpoint: "allVideoInfo/id/\(videoId)")
    }

    func getTranscodedFiles(videoId: String) async throws -> [TranscodeFile] {
        try await makeRequest(endpoint: "transcoddedFiles/id/\(videoId)")
    }

    func getTranslationFiles(videoId: String) async throws -> [TranslationInfo] {
        try await makeRequest(endpoint: "translationFiles/id/\(videoId)")
    }

    func getSeriesEpisodes(rootEpisodeId: String) async throws -> [VideoModel] {
        try await makeRequest(endpoint: "videoSeason/id/\(rootEpisodeId)")
    }

    // MARK: - Search & Categories

    func searchVideos(
        query: String? = nil,
        type: String? = nil,
        year: String? = nil,
        categoryId: String? = nil,
        page: Int = 1,
        parentalLevel: Int = 0
    ) async throws -> [VideoModel] {
        var params: [String] = []
        if let query = query { params.append("videoTitle=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)") }
        if let type = type { params.append("type=\(type)") }
        if let year = year { params.append("year=\(year)") }
        if let categoryId = categoryId { params.append("category_id=\(categoryId)") }
        params.append("page=\(page)")
        params.append("level=\(parentalLevel)")

        let queryString = params.joined(separator: "&")
        return try await makeRequest(endpoint: "AdvancedSearch?\(queryString)")
    }

    func getCategories() async throws -> [NewCategoryItem] {
        try await makeRequest(endpoint: "categories")
    }

    func getAvailableSearchYears() async throws -> [SearchYearItem] {
        try await makeRequest(endpoint: "AvailableSearchYears")
    }

    func getCollections(parentalLevel: Int = 0) async throws -> [CollectionItem] {
        try await makeRequest(endpoint: "collectionsId")
    }

    func getCollectionDetails(collectionId: String, parentalLevel: Int = 0) async throws -> [VideoModel] {
        try await makeRequest(endpoint: "collectionVideos/collectionID/\(collectionId)/level/\(parentalLevel)")
    }

    // MARK: - Video Pagination

    func getVideoListPagination(groupId: String, parentalLevel: Int = 0, itemsPerPage: Int = 20, page: Int = 1) async throws -> [VideoModel] {
        try await makeRequest(
            endpoint: "videoListPagination/groupID/\(groupId)/level/\(parentalLevel)/itemsPerPage/\(itemsPerPage)/page/\(page)"
        )
    }

    // MARK: - User Actions

    func addToHistory(videoId: String, kind: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "videoId": videoId,
            "kind": kind
        ])
        let _: EmptyResponse = try await makeRequest(endpoint: "addToHistory/", method: "POST", body: body, requiresAuth: true)
    }

    func getHistory(pageNumber: Int = 1, parentalLevel: Int = 0) async throws -> [VideoModel] {
        try await makeRequest(endpoint: "history/level/\(parentalLevel)/pageNumber/\(pageNumber)", requiresAuth: true)
    }

    func removeFromHistory(videoId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["videoId": videoId])
        let _: EmptyResponse = try await makeRequest(endpoint: "removeFromHistory/", method: "POST", body: body, requiresAuth: true)
    }

    func removeAllHistory() async throws {
        let _: EmptyResponse = try await makeRequest(endpoint: "removeAllWatchHistory/", method: "POST", body: nil, requiresAuth: true)
    }

    func addLike(videoId: String, likeValue: Int) async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "videoId": videoId,
            "likeValue": likeValue
        ])
        let _: EmptyResponse = try await makeRequest(endpoint: "addLike/", method: "POST", body: body, requiresAuth: true)
    }

    func checkVideoStatus(videoId: String) async throws -> VideoWatchStatus {
        try await makeRequest(endpoint: "memberCheckVideoStatus/id/\(videoId)", requiresAuth: true)
    }

    // MARK: - Subscriptions

    func getSubscriptions() async throws -> [VideoModel] {
        try await makeRequest(endpoint: "get_subscriptions", requiresAuth: true)
    }

    func addSubscription(videoId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["video_id": videoId])
        let _: EmptyResponse = try await makeRequest(endpoint: "add_subscriptions/", method: "POST", body: body, requiresAuth: true)
    }

    func removeSubscription(videoId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["video_id": videoId])
        let _: EmptyResponse = try await makeRequest(endpoint: "remove_subscriptions/", method: "POST", body: body, requiresAuth: true)
    }

    func getSubscriptionStatus(videoId: String) async throws -> SubscriptionStatus {
        try await makeRequest(endpoint: "get_subscription_status/videoId/\(videoId)", requiresAuth: true)
    }

    // MARK: - User Settings

    func getUserSettings(language: String = "en") async throws -> UserSettings {
        try await makeRequest(endpoint: "userSettings/lang/\(language)", requiresAuth: true)
    }

    func updateTranslationSettings(enabled: Bool) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["translationState": enabled])
        let _: EmptyResponse = try await makeRequest(endpoint: "UserTranslationSettings", method: "POST", body: body, requiresAuth: true)
    }

    // MARK: - Notifications

    func getNotifications(count: Int = 20) async throws -> NotificationsResponse {
        let body = try JSONSerialization.data(withJSONObject: ["count": count])
        return try await makeRequest(endpoint: "get_notifications/", method: "POST", body: body, requiresAuth: true)
    }

    func setNotificationViewed(notificationId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["notificationId": notificationId])
        let _: EmptyResponse = try await makeRequest(endpoint: "set_notifications_viewed/", method: "POST", body: body, requiresAuth: true)
    }

    // MARK: - Parental Level

    func checkVideoParentalLevel(videoId: String) async throws -> Bool {
        let response: ParentalCheckResponse = try await makeRequest(
            endpoint: "checkVideoParentalLevel/videoId/\(videoId)",
            requiresAuth: true
        )
        return response.allowed ?? true
    }

    // MARK: - Recommendations

    func getRecommendations(movieId: String) async throws -> [VideoModel] {
        try await makeRequest(
            endpoint: "recommend?MovieId=\(movieId)",
            baseURL: recommendBaseURL
        )
    }

    // MARK: - Staff/Actor Info

    func getStaffInfo(actorId: String, parentalLevel: Int = 0) async throws -> StaffInfo {
        try await makeRequest(endpoint: "staff/actorID/\(actorId)/level/\(parentalLevel)")
    }

    // MARK: - Device Login

    func registerDevice(deviceId: String, deviceName: String, playerId: String? = nil) async throws {
        var bodyDict: [String: String] = [
            "deviceId": deviceId,
            "deviceName": deviceName
        ]
        if let playerId = playerId {
            bodyDict["playerId"] = playerId
        }

        let body = try JSONSerialization.data(withJSONObject: bodyDict)
        let _: EmptyResponse = try await makeRequest(
            endpoint: "core/api/device",
            baseURL: identityBaseURL,
            method: "POST",
            body: body,
            requiresAuth: true
        )
    }
}

// MARK: - API Error & Response Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

struct EmptyResponse: Codable {}

struct ParentalCheckResponse: Codable {
    let allowed: Bool?
    let message: String?
}