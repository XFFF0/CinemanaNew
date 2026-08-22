import Foundation

// MARK: - VideoItem (Search / Browse / Banner)
struct VideoItem: Identifiable, Codable {
    let id: String
    let arTitle: String?
    let enTitle: String?
    let year: String?
    let stars: String?
    let kind: String?
    let season: String?
    let imgObjUrl: String?
    let imgThumbObjUrl: String?
    let imgMediumThumbObjUrl: String?
    let filmRating: String?
    let mDate: String?
    let trailer: String?
    let imdbUrlRef: String?
    let enContent: String?
    let arContent: String?
    let episodeNummer: String?
    let rootId: String?

    enum CodingKeys: String, CodingKey {
        case id = "nb"
        case arTitle = "ar_title"; case enTitle = "en_title"
        case year, stars, kind, season
        case imgObjUrl, imgThumbObjUrl, imgMediumThumbObjUrl
        case filmRating, mDate, trailer, imdbUrlRef
        case enContent = "en_content"; case arContent = "ar_content"
        case episodeNummer; case rootId
    }
    var displayTitle: String { enTitle ?? arTitle ?? "Unknown" }
    var isMovie:  Bool { kind == "1" }
    var isSeries: Bool { kind == "2" }

    func cleanURL(_ raw: String?) -> URL? {
        guard let r = raw, !r.isEmpty else { return nil }
        return URL(string: r.replacingOccurrences(of: "\\/", with: "/"))
    }
    var thumbURL:  URL? { cleanURL(imgThumbObjUrl) ?? cleanURL(imgMediumThumbObjUrl) ?? cleanURL(imgObjUrl) }
    var medURL:    URL? { cleanURL(imgMediumThumbObjUrl) ?? cleanURL(imgObjUrl) ?? cleanURL(imgThumbObjUrl) }
    var fullURL:   URL? { cleanURL(imgObjUrl) ?? cleanURL(imgMediumThumbObjUrl) ?? cleanURL(imgThumbObjUrl) }
    var trailerURL:URL? { cleanURL(trailer) }
    var imdbURL:   URL? { cleanURL(imdbUrlRef) }
}

// MARK: - TranscodedFile
struct TranscodedFile: Codable, Identifiable {
    let id: String
    let resolution: String?
    let file: String?
    enum CodingKeys: String, CodingKey { case id = "nb"; case resolution, file }
    var streamURL: URL? {
        guard let f = file else { return nil }
        return URL(string: f.replacingOccurrences(of: "\\/", with: "/"))
    }
}

// MARK: - SeasonEpisode
struct SeasonEpisode: Codable, Identifiable {
    let id: String
    let enTitle: String?
    let arTitle: String?
    let episodeNummer: String?
    let season: String?
    let imgThumbObjUrl: String?
    enum CodingKeys: String, CodingKey {
        case id = "nb"; case enTitle = "en_title"; case arTitle = "ar_title"
        case episodeNummer, season, imgThumbObjUrl
    }
    var displayTitle: String { enTitle ?? arTitle ?? "Episode \(episodeNummer ?? "?")" }
    var thumbURL: URL? {
        guard let r = imgThumbObjUrl, !r.isEmpty else { return nil }
        return URL(string: r.replacingOccurrences(of: "\\/", with: "/"))
    }
}

// MARK: - VideoCategory
struct VideoCategory: Codable, Identifiable {
    let id: String
    let enTitle: String?
    let arTitle: String?
    enum CodingKeys: String, CodingKey { case id = "nb"; case enTitle = "en_title"; case arTitle = "ar_title" }
    var displayTitle: String { enTitle ?? arTitle ?? "Category" }
}

// MARK: - VideoGroup
struct VideoGroup: Codable, Identifiable {
    let id: String
    let enTitle: String?
    let arTitle: String?
    enum CodingKeys: String, CodingKey { case id = "nb"; case enTitle = "en_title"; case arTitle = "ar_title" }
    var displayTitle: String { enTitle ?? arTitle ?? "Group" }
}

// MARK: - Comment
struct VideoComment: Codable, Identifiable {
    let id: String
    let comment: String?
    let userName: String?
    let itemDate: String?
    enum CodingKeys: String, CodingKey { case id = "nb"; case comment; case userName = "user_name"; case itemDate = "itemDate" }
}

// MARK: - Actor/Staff
struct StaffItem: Codable, Identifiable {
    let id: String
    let enName: String?
    let arName: String?
    let imgObjUrl: String?
    enum CodingKeys: String, CodingKey { case id = "nb"; case enName = "en_name"; case arName = "ar_name"; case imgObjUrl }
    var displayName: String { enName ?? arName ?? "Unknown" }
    var photoURL: URL? {
        guard let r = imgObjUrl, !r.isEmpty else { return nil }
        return URL(string: r.replacingOccurrences(of: "\\/", with: "/"))
    }
}

// MARK: - Collection
struct VideoCollection: Codable, Identifiable {
    let id: String
    let enTitle: String?
    let arTitle: String?
    enum CodingKeys: String, CodingKey { case id = "nb"; case enTitle = "en_title"; case arTitle = "ar_title" }
    var displayTitle: String { enTitle ?? arTitle ?? "Collection" }
}

// MARK: - StatusPage Component
struct StatusComponent: Codable, Identifiable {
    let id: String
    let name: String?
    let status: String?
}
struct StatusResponse: Codable {
    let components: [StatusComponent]?
}
