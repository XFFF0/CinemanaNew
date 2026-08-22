import Foundation

// MARK: - All 36 Cinemana endpoints + 12 account endpoints from APK analysis
enum API {
    static let base    = "https://cinemana.shabakaty.com/api/android/"
    static let account = "https://account.shabakaty.com/"
    static let recommend = "https://recommend.shabakaty.com/api/recommendation/recommend/"
    static let statusPage = "https://6b1m6vnfz2jk.statuspage.io/api/v2/components.json"
    // User-Agent mirrors the interceptor from AuthorizationInterceptor.java
    static let ua = "Dalvik/2.1.0 (Linux; Android 10; Cinemana/5.3.3)"
}

final class NetworkService {
    static let shared = NetworkService()
    var authToken: String?
    private let session: URLSession

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 15
        cfg.timeoutIntervalForResource = 30
        session = URLSession(configuration: cfg)
    }

    // MARK: - Helpers
    private func req(_ url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.setValue(API.ua, forHTTPHeaderField: "User-Agent")
        if let token = authToken {
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let b = body {
            r.httpBody = b
            r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        return r
    }

    private func get<T: Decodable>(_ path: String,
                                   params: [String: String] = [:],
                                   completion: @escaping (Result<T, Error>) -> Void) {
        var comps = URLComponents(string: API.base + path)!
        if !params.isEmpty {
            comps.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = comps.url else { return }
        session.dataTask(with: req(url)) { data, _, error in
            self.decode(data: data, error: error, completion: completion)
        }.resume()
    }

    private func post<T: Decodable>(_ path: String,
                                    form: [String: String],
                                    base: String = API.base,
                                    completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: base + path) else { return }
        let body = form.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                       .joined(separator: "&").data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            self.decode(data: data, error: error, completion: completion)
        }.resume()
    }

    private func decode<T: Decodable>(data: Data?, error: Error?, completion: (Result<T, Error>) -> Void) {
        if let error = error { completion(.failure(error)); return }
        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: 0))); return
        }
        do {
            completion(.success(try JSONDecoder().decode(T.self, from: data)))
        } catch {
            completion(.failure(error))
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: CINEMANA MAIN — 36 endpoints
    // ─────────────────────────────────────────────────────────────────

    // #1 GET allVideoInfo/id/{videoNb}
    func allVideoInfo(id: String, completion: @escaping (Result<VideoItem, Error>) -> Void) {
        get("allVideoInfo/id/\(id)", completion: completion)
    }

    // #2 POST logout/
    func logout(deviceId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "logout/") else { return }
        let body = "deviceId=\(deviceId)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #3 POST addLike/
    func addLike(userId: String, videoId: String, likeValue: Int,
                 completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "addLike/") else { return }
        let body = "userId=\(userId)&videoId=\(videoId)&likeValue=\(likeValue)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #4 GET categories
    func categories(completion: @escaping (Result<[VideoCategory], Error>) -> Void) {
        get("categories", completion: completion)
    }

    // #5 POST commentSpam/
    func commentSpam(userID: String, videoID: String, commentID: String,
                     completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "commentSpam/") else { return }
        let body = "userID=\(userID)&videoID=\(videoID)&commentID=\(commentID)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #6 GET getCollection/collectionID/{id}/level/{level}
    func getCollection(id: String, level: Int = 0,
                       completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        get("getCollection/collectionID/\(id)/level/\(level)", completion: completion)
    }

    // #7 GET AdvancedSearch
    func search(title: String, type: String = "movie", page: Int = 1,
                categoryId: String? = nil, year: String? = nil, star: String? = nil,
                completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        var p: [String: String] = [
            "videoTitle": title, "type": type,
            "page": "\(page)", "level": "0"
        ]
        if let c = categoryId { p["category_id"] = c }
        if let y = year       { p["year"] = y }
        if let s = star       { p["star"] = s }
        get("AdvancedSearch", params: p, completion: completion)
    }

    // #8 GET collectionsId/level/{parentalLevel}
    func collectionsId(level: Int = 0,
                       completion: @escaping (Result<[VideoCollection], Error>) -> Void) {
        get("collectionsId/level/\(level)", completion: completion)
    }

    // #9 GET userSettings/lang/{language}
    func userSettings(lang: Int = 1, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "userSettings/lang/\(lang)") else { return }
        session.dataTask(with: req(url)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #10 GET memberCheckVideoStatus/id/{videoNb}
    func memberCheckVideoStatus(id: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "memberCheckVideoStatus/id/\(id)") else { return }
        session.dataTask(with: req(url)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #11 GET videoSeason/id/{rootEpisodeId}
    func videoSeason(id: String, completion: @escaping (Result<[SeasonEpisode], Error>) -> Void) {
        get("videoSeason/id/\(id)", completion: completion)
    }

    // #12 GET banner/level/{parentalLevel}
    func banner(level: Int = 0, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        get("banner/level/\(level)", completion: completion)
    }

    // #13 POST removeFromHistory/
    func removeFromHistory(userId: String, videoId: String, kind: Int,
                           completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "removeFromHistory/") else { return }
        let body = "userId=\(userId)&videoId=\(videoId)&kind=\(kind)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #14 POST history/
    func history(userId: String, page: Int = 1, kind: Int = 1,
                 completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        guard let url = URL(string: API.base + "history/") else { return }
        let body = "pageNumber=\(page)&userId=\(userId)&kind=\(kind)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            self.decode(data: data, error: error, completion: completion)
        }.resume()
    }

    // #15 POST addComment/
    func addComment(id: String, videoId: String, comment: String,
                    completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "addComment/") else { return }
        let enc = comment.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? comment
        let body = "id=\(id)&videoId=\(videoId)&comment=\(enc)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #16 GET newlyVideosItems/level/{parentalLevel}/offset/12/
    func newlyVideos(level: Int = 0, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        get("newlyVideosItems/level/\(level)/offset/12/", completion: completion)
    }

    // #17 GET videoComment/id/{videoNb}
    func videoComments(id: String, completion: @escaping (Result<[VideoComment], Error>) -> Void) {
        get("videoComment/id/\(id)", completion: completion)
    }

    // #18 GET videoGroups/lang/{language}/level/{parentalLevel}
    func videoGroups(lang: Int = 1, level: Int = 0,
                     completion: @escaping (Result<[VideoGroup], Error>) -> Void) {
        get("videoGroups/lang/\(lang)/level/\(level)", completion: completion)
    }

    // #19 GET commentRules
    func commentRules(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "commentRules") else { return }
        session.dataTask(with: req(url)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #20 POST changeParentalLevel
    func changeParentalLevel(level: Int, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "changeParentalLevel") else { return }
        let body = "parentalLevel=\(level)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #21 GET statuspage
    func serviceStatus(completion: @escaping (Result<StatusResponse, Error>) -> Void) {
        guard let url = URL(string: API.statusPage) else { return }
        session.dataTask(with: req(url)) { data, _, error in
            self.decode(data: data, error: error, completion: completion)
        }.resume()
    }

    // #22 POST highlightEpisode/
    func highlightEpisode(videoID: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "highlightEpisode/") else { return }
        let body = "videoID=\(videoID)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #23 POST UserTranslationSettings
    func userTranslationSettings(enable: Bool, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "UserTranslationSettings") else { return }
        let body = "enableNonTranslation=\(enable ? 1 : 0)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #24 GET video/V/2
    func browseVideos(categoryNb: String? = nil, videoKind: Int = 1,
                      lang: Int = 1, page: Int = 1, perPage: Int = 20,
                      completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        var p: [String: String] = [
            "videoKind": "\(videoKind)", "langNb": "\(lang)",
            "itemsPerPage": "\(perPage)", "pageNumber": "\(page)",
            "level": "0", "sortParam": "1"
        ]
        if let c = categoryNb { p["categoryNb"] = c }
        get("video/V/2", params: p, completion: completion)
    }

    // #25 POST recommend
    func recommend(movieId: String, movieName: String,
                   completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.recommend) else { return }
        let json = "{\"MovieId\":\"\(movieId)\",\"MovieName\":\"\(movieName)\",\"ReProcessIfExpired\":false}"
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.setValue(API.ua, forHTTPHeaderField: "User-Agent")
        r.httpBody = json.data(using: .utf8)
        session.dataTask(with: r) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #26 POST get_subscriptions
    func getSubscriptions(completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        guard let url = URL(string: API.base + "get_subscriptions") else { return }
        session.dataTask(with: req(url, method: "POST")) { data, _, error in
            self.decode(data: data, error: error, completion: completion)
        }.resume()
    }

    // #27 POST get_notifications
    func getNotifications(count: Int = 20, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "get_notifications") else { return }
        let body = "count=\(count)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #28 POST updateComment/
    func updateComment(id: String, videoId: String, commentId: String, comment: String,
                       completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "updateComment/") else { return }
        let enc = comment.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? comment
        let body = "id=\(id)&videoId=\(videoId)&commentId=\(commentId)&comment=\(enc)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #29 POST login/
    func login(deviceId: String, deviceName: String, playerId: String,
               completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "login/") else { return }
        let body = "deviceId=\(deviceId)&deviceName=\(deviceName)&playerId=\(playerId)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #30 POST addToHistory/
    func addToHistory(userId: String, videoId: String, kind: Int,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "addToHistory/") else { return }
        let body = "userId=\(userId)&videoId=\(videoId)&kind=\(kind)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #31 GET videoListPagination
    func videoListPagination(groupID: String, page: Int = 1, perPage: Int = 20,
                             completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        get("videoListPagination", params: [
            "groupID": groupID, "level": "0",
            "itemsPerPage": "\(perPage)", "page": "\(page)"
        ], completion: completion)
    }

    // #32 POST add_subscriptions/
    func addSubscription(userId: String, videoId: String,
                         completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "add_subscriptions/") else { return }
        let body = "userId=\(userId)&video_id=\(videoId)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #33 GET staff/actorID/{actorID}/level/{level}
    func staff(actorID: String, level: Int = 0,
               completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        get("staff/actorID/\(actorID)/level/\(level)", completion: completion)
    }

    // #34 POST removeComment/
    func removeComment(id: String, videoId: String, commentId: String,
                       completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "removeComment/") else { return }
        let body = "id=\(id)&videoId=\(videoId)&commentId=\(commentId)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #35 POST remove_subscriptions/
    func removeSubscription(userId: String, videoId: String,
                            completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.base + "remove_subscriptions/") else { return }
        let body = "userId=\(userId)&video_id=\(videoId)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // #36 GET transcoddedFiles/id/{videoNb}
    func transcoddedFiles(id: String, completion: @escaping (Result<[TranscodedFile], Error>) -> Void) {
        get("transcoddedFiles/id/\(id)", completion: completion)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: ACCOUNT — 12 endpoints (account.shabakaty.com)
    // ─────────────────────────────────────────────────────────────────

    // A1 POST core/api/password
    func changePassword(old: String, new: String, confirm: String,
                        completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.account + "core/api/password") else { return }
        let json = "{\"oldpassword\":\"\(old)\",\"newpassword\":\"\(new)\",\"confirmpassword\":\"\(confirm)\"}"
        var r = req(url, method: "POST")
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = json.data(using: .utf8)
        session.dataTask(with: r) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // A2 POST core/api/password/mobile-forgot-password
    func forgotPassword(email: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.account + "core/api/password/mobile-forgot-password") else { return }
        let json = "{\"Email\":\"\(email)\"}"
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = json.data(using: .utf8)
        session.dataTask(with: r) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // A3 POST core/connect/token (login with password)
    func accountLogin(username: String, password: String, clientId: String,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.account + "core/connect/token") else { return }
        let body = "username=\(username)&password=\(password)&scope=openid&grant_type=password".data(using: .utf8)
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        r.setValue("Basic \(Data("\(clientId):".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        r.httpBody = body
        session.dataTask(with: r) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // A6 GET core/connect/userinfo
    func userInfo(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.account + "core/connect/userinfo") else { return }
        session.dataTask(with: req(url)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // A7 POST core/connect/token (refresh)
    func refreshToken(refreshToken: String, clientId: String,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.account + "core/connect/token") else { return }
        let body = "refresh_token=\(refreshToken)&scope=openid&grant_type=refresh_token".data(using: .utf8)
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        r.setValue("Basic \(Data("\(clientId):".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        r.httpBody = body
        session.dataTask(with: r) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // A9 POST core/api/password/mobile-reset
    func resetPassword(email: String, password: String, confirm: String, code: String,
                       completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.account + "core/api/password/mobile-reset") else { return }
        let json = "{\"Email\":\"\(email)\",\"Password\":\"\(password)\",\"ConfirmPassword\":\"\(confirm)\",\"Code\":\"\(code)\"}"
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = json.data(using: .utf8)
        session.dataTask(with: r) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // A11 POST core/api/account
    func updateAccount(phone: String, gender: Int, firstName: String, lastName: String,
                       country: String, city: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: API.account + "core/api/account") else { return }
        let body = "phoneNumber=\(phone)&gender=\(gender)&firstName=\(firstName)&lastName=\(lastName)&country=\(country)&city=\(city)".data(using: .utf8)
        session.dataTask(with: req(url, method: "POST", body: body)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }

    // A12 GET core/api/device
    func checkDevice(userCode: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard var comps = URLComponents(string: API.account + "core/api/device") else { return }
        comps.queryItems = [URLQueryItem(name: "userCode", value: userCode)]
        guard let url = comps.url else { return }
        session.dataTask(with: req(url)) { data, _, error in
            if let e = error { completion(.failure(e)); return }
            completion(.success(data ?? Data()))
        }.resume()
    }
}
