import Foundation

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

    enum CodingKeys: String, CodingKey {
        case id = "nb"
        case arTitle = "ar_title"
        case enTitle = "en_title"
        case year, stars, kind, season
        case imgObjUrl, imgThumbObjUrl, imgMediumThumbObjUrl
        case filmRating, mDate, trailer, imdbUrlRef
        case enContent = "en_content"
        case arContent = "ar_content"
    }

    var displayTitle: String { enTitle ?? arTitle ?? "Unknown" }
    var isMovie: Bool { kind == "1" }
    var isSeries: Bool { kind == "2" }
}

struct TranscodedFile: Codable, Identifiable {
    let id: String
    let resolution: String?
    let file: String?
    enum CodingKeys: String, CodingKey {
        case id = "nb"; case resolution, file
    }
}

struct SeasonEpisode: Codable, Identifiable {
    let id: String
    let enTitle: String?
    let arTitle: String?
    let episodeNummer: String?
    let season: String?
    let imgThumbObjUrl: String?
    enum CodingKeys: String, CodingKey {
        case id = "nb"
        case enTitle = "en_title"; case arTitle = "ar_title"
        case episodeNummer, season, imgThumbObjUrl
    }
    var displayTitle: String { enTitle ?? arTitle ?? "Episode \(episodeNummer ?? "?")" }
}

struct VideoCategory: Codable, Identifiable {
    let id: String
    let enTitle: String?
    let arTitle: String?
    enum CodingKeys: String, CodingKey {
        case id = "nb"; case enTitle = "en_title"; case arTitle = "ar_title"
    }
    var displayTitle: String { enTitle ?? arTitle ?? "Category" }
}
