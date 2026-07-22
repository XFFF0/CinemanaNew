import Foundation

enum APIError: Error, CustomStringConvertible {
    case invalidURL
    case server(Int, String)
    case decoding(Error, String)
    case network(Error)

    var description: String {
        switch self {
        case .invalidURL: return "رابط غير صالح"
        case .server(let code, let body): return "خطأ سيرفر (\(code)): \(body.prefix(300))"
        case .decoding(let err, let body): return "خطأ بتحليل البيانات: \(err.localizedDescription)\nالرد الخام: \(body.prefix(300))"
        case .network(let err): return "خطأ شبكة: \(err.localizedDescription)"
        }
    }
}

enum HTTPMethod: String { case get = "GET", post = "POST", patch = "PATCH" }

/// Matches endpoints documented in cinemana-api.md (ApiServices.kt).
final class APIClient {
    static let shared = APIClient()

    private let mainBaseURL = URL(string: "https://cinemana.shabakaty.com/api/android/")!
    private let infoBaseURL = URL(string: "https://cinemana.shabakaty.com")!
    private let recommendBaseURL = URL(string: "https://recommend.shabakaty.com/api/recommendation/recommend/")!
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Generic request

    @discardableResult
    private func request<T: Decodable>(
        _ path: String,
        base: URL? = nil,
        method: HTTPMethod = .get,
        query: [String: String] = [:],
        form: [String: String]? = nil,
        cacheControl: String? = "cacheable-for-authorized, max-age=300"
    ) async throws -> T {
        let root = base ?? mainBaseURL
        var components = URLComponents(url: root.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue

        if let token = await AuthService.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let cacheControl {
            req.setValue(cacheControl, forHTTPHeaderField: "Cache-Control")
        }
        if let form {
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = form.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        }

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw APIError.network(URLError(.badServerResponse)) }
            let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8, \(data.count) bytes>"
            #if DEBUG
            print("➡️ \(method.rawValue) \(url.absoluteString)")
            print("⬅️ [\(http.statusCode)] \(rawBody.prefix(500))")
            #endif
            guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode, rawBody) }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error, rawBody)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error)
        }
    }

    // MARK: - Home / Discovery

    func videoGroups(language: String, level: String) async throws -> [VideoGroup] {
        let response: VideoGroupsResponse = try await request("videoGroups/lang/\(language)/level/\(level)")
        return response.groups
    }

    func banners(level: String) async throws -> [Banner] {
        try await request("banner/level/\(level)")
    }

    func newlyAdded(level: String) async throws -> [VideoModel] {
        try await request("newlyVideosItems/level/\(level)/offset/12/")
    }

    func categories() async throws -> [Category] {
        try await request("categories")
    }

    func collections(level: String) async throws -> [CollectionModel] {
        try await request("collectionsId/level/\(level)")
    }

    func collection(id: String, level: String) async throws -> [VideoModel] {
        try await request("getCollection/collectionID/\(id)/level/\(level)")
    }

    // MARK: - Search

    func advancedSearch(title: String? = nil, type: String? = nil, year: String? = nil,
                         categoryId: String? = nil, star: String? = nil,
                         page: Int = 1, level: String) async throws -> [VideoModel] {
        var query: [String: String] = ["page": "\(page)", "level": level]
        if let title { query["videoTitle"] = title }
        if let type { query["type"] = type }
        if let year { query["year"] = year }
        if let categoryId { query["category_id"] = categoryId }
        if let star { query["star"] = star }
        return try await request("AdvancedSearch", query: query)
    }

    // MARK: - Video detail

    func videoInfo(id: String) async throws -> VideoModel {
        try await request("allVideoInfo/id/\(id)")
    }

    func videoSeasons(rootEpisodeId: String) async throws -> [VideoModel] {
        try await request("videoSeason/id/\(rootEpisodeId)")
    }

    func transcodedFiles(id: String) async throws -> [TranscodedFile] {
        try await request("transcoddedFiles/id/\(id)")
    }

    func comments(videoId: String) async throws -> [VideoComment] {
        try await request("videoComment/id/\(videoId)")
    }

    func addComment(userId: String, videoId: String, comment: String) async throws {
        let _: EmptyResponse = try await request("addComment/", method: .post,
            form: ["id": userId, "videoId": videoId, "comment": comment])
    }

    func addLike(userId: String, videoId: String, likeValue: String) async throws {
        let _: EmptyResponse = try await request("addLike/", method: .post,
            form: ["userId": userId, "videoId": videoId, "likeValue": likeValue])
    }

    // MARK: - User / history / subscriptions

    func history(userId: String, page: Int, kind: String) async throws -> [VideoModel] {
        try await request("history/", method: .post,
            form: ["pageNumber": "\(page)", "userId": userId, "kind": kind])
    }

    func addToHistory(userId: String, videoId: String, kind: String) async throws {
        let _: EmptyResponse = try await request("addToHistory/", method: .post,
            form: ["userId": userId, "videoId": videoId, "kind": kind])
    }

    func removeFromHistory(userId: String, videoId: String, kind: String) async throws {
        let _: EmptyResponse = try await request("removeFromHistory/", method: .post,
            form: ["userId": userId, "videoId": videoId, "kind": kind])
    }

    func subscribe(userId: String, videoId: String) async throws {
        let _: EmptyResponse = try await request("add_subscriptions/", method: .post,
            form: ["userId": userId, "video_id": videoId])
    }

    func unsubscribe(userId: String, videoId: String) async throws {
        let _: EmptyResponse = try await request("remove_subscriptions/", method: .post,
            form: ["userId": userId, "video_id": videoId])
    }

    func changeParentalLevel(_ level: String) async throws {
        let _: EmptyResponse = try await request("changeParentalLevel", method: .post,
            form: ["parentalLevel": level])
    }

    // MARK: - Analytics (ShabakatyInfo)

    func sendAnalytics(deviceType: String, userId: String, identifier: String, eventsJSON: String) async throws {
        let _: EmptyResponse = try await request("/api/info/ShabakatyInfo", base: infoBaseURL, method: .post,
            form: [
                "deviceType": deviceType,
                "userID": userId,
                "identifier": identifier,
                "platform_type": "ios",
                "analytics": eventsJSON
            ], cacheControl: nil)
    }
}

/// Used for POST endpoints that return no meaningful decodable body.
struct EmptyResponse: Decodable {}
