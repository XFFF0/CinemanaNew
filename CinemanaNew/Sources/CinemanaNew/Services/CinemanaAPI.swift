import Foundation

// MARK: - API Constants (from cinemana-5-3-3 APK analysis)
enum CinemanaAPI {
    static let baseURL      = "https://cinemana.shabakaty.com/api/android/"
    static let accountURL   = "https://account.shabakaty.com/"
    static let recommendURL = "https://recommend.shabakaty.com/api/recommendation/recommend/"

    // User-Agent matching the interceptor pattern from AuthorizationInterceptor.java
    static let userAgent    = "Cinemana/5.3.3 (Android; CinemanaNew-iOS)"

    enum Endpoint {
        static let advancedSearch       = "AdvancedSearch"
        static let allVideoInfo         = "allVideoInfo/id/"
        static let transcoddedFiles     = "transcoddedFiles/id/"
        static let videoSeason          = "videoSeason/id/"
        static let banner               = "banner/level/0"
        static let categories           = "categories"
        static let videoGroups          = "videoGroups/lang/1/level/0"
        static let videoListPagination  = "videoListPagination"
        static let videoV2              = "video/V/2"
        static let newlyVideosItems     = "newlyVideosItems/level/0/offset/12/"
        static let videoComment         = "videoComment/id/"
        static let staff                = "staff/actorID/"
        static let addLike              = "addLike/"
        static let addComment           = "addComment/"
        static let addToHistory         = "addToHistory/"
        static let removeFromHistory    = "removeFromHistory/"
        static let history              = "history/"
        static let getSubscriptions     = "get_subscriptions"
        static let addSubscriptions     = "add_subscriptions/"
        static let removeSubscriptions  = "remove_subscriptions/"
        static let login                = "login/"
        static let logout               = "logout/"
    }
}

// MARK: - Network Service
class NetworkService {
    static let shared = NetworkService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 15
        config.timeoutIntervalForResource = 15
        session = URLSession(configuration: config)
    }

    private func makeRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(CinemanaAPI.userAgent, forHTTPHeaderField: "User-Agent")
        return req
    }

    // MARK: - Search (endpoint #7: GET AdvancedSearch)
    // Params: videoTitle, staffTitle, type, year, category_id, star, page, level
    func search(title: String,
                type: String = "movie",
                page: Int = 1,
                categoryId: String? = nil,
                completion: @escaping (Result<[VideoItem], Error>) -> Void) {

        var comps = URLComponents(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.advancedSearch)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "videoTitle",  value: title),
            URLQueryItem(name: "type",        value: type),
            URLQueryItem(name: "page",        value: "\(page)"),
            URLQueryItem(name: "level",       value: "0")
        ]
        if let cat = categoryId { items.append(URLQueryItem(name: "category_id", value: cat)) }
        comps.queryItems = items
        guard let url = comps.url else { return }

        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let items = try JSONDecoder().decode([VideoItem].self, from: data)
                completion(.success(items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Video Info (endpoint #1: GET allVideoInfo/id/{videoNb})
    func videoInfo(id: String, completion: @escaping (Result<VideoItem, Error>) -> Void) {
        guard let url = URL(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.allVideoInfo + id) else { return }
        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let item = try JSONDecoder().decode(VideoItem.self, from: data)
                completion(.success(item))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    // MARK: - Transcoded Files (endpoint #36: GET transcoddedFiles/id/{videoNb})
    func transcoddedFiles(id: String, completion: @escaping (Result<[TranscodedFile], Error>) -> Void) {
        guard let url = URL(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.transcoddedFiles + id) else { return }
        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let files = try JSONDecoder().decode([TranscodedFile].self, from: data)
                completion(.success(files))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    // MARK: - Video Season (endpoint #11: GET videoSeason/id/{rootEpisodeId})
    func videoSeason(id: String, completion: @escaping (Result<[SeasonEpisode], Error>) -> Void) {
        guard let url = URL(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.videoSeason + id) else { return }
        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let eps = try JSONDecoder().decode([SeasonEpisode].self, from: data)
                completion(.success(eps))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    // MARK: - Banner (endpoint #12: GET banner/level/{parentalLevel})
    func banner(completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        guard let url = URL(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.banner) else { return }
        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let items = try JSONDecoder().decode([VideoItem].self, from: data)
                completion(.success(items))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    // MARK: - Newly Videos (endpoint #16: GET newlyVideosItems/level/{parentalLevel}/offset/12/)
    func newlyVideos(completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        guard let url = URL(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.newlyVideosItems) else { return }
        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let items = try JSONDecoder().decode([VideoItem].self, from: data)
                completion(.success(items))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    // MARK: - Categories (endpoint #4: GET categories)
    func categories(completion: @escaping (Result<[VideoCategory], Error>) -> Void) {
        guard let url = URL(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.categories) else { return }
        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let cats = try JSONDecoder().decode([VideoCategory].self, from: data)
                completion(.success(cats))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    // MARK: - Video/V/2 browse (endpoint #24)
    func browseVideos(categoryNb: String? = nil,
                      videoKind: Int = 1,
                      langNb: Int = 1,
                      page: Int = 1,
                      itemsPerPage: Int = 20,
                      completion: @escaping (Result<[VideoItem], Error>) -> Void) {

        var comps = URLComponents(string: CinemanaAPI.baseURL + CinemanaAPI.Endpoint.videoV2)!
        var qi: [URLQueryItem] = [
            URLQueryItem(name: "videoKind",    value: "\(videoKind)"),
            URLQueryItem(name: "langNb",       value: "\(langNb)"),
            URLQueryItem(name: "itemsPerPage", value: "\(itemsPerPage)"),
            URLQueryItem(name: "pageNumber",   value: "\(page)"),
            URLQueryItem(name: "level",        value: "0"),
            URLQueryItem(name: "sortParam",    value: "1")
        ]
        if let cat = categoryNb { qi.append(URLQueryItem(name: "categoryNb", value: cat)) }
        comps.queryItems = qi
        guard let url = comps.url else { return }

        session.dataTask(with: makeRequest(url: url)) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let items = try JSONDecoder().decode([VideoItem].self, from: data)
                completion(.success(items))
            } catch { completion(.failure(error)) }
        }.resume()
    }
}
