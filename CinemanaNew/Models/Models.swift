import Foundation

// MARK: - API Envelope (maps to obfuscated xs3<T> wrapper from RE report)

struct APIEnvelope<T: Decodable>: Decodable {
    let status: Int?
    let data: T?

    private enum CodingKeys: String, CodingKey {
        case status, data, v, a
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Some endpoints use v/a (obfuscated), others use status/data directly.
        self.status = try container.decodeIfPresent(Int.self, forKey: .status)
            ?? container.decodeIfPresent(Int.self, forKey: .v)
        self.data = try container.decodeIfPresent(T.self, forKey: .data)
            ?? container.decodeIfPresent(T.self, forKey: .a)
    }
}

// MARK: - Video

struct VideoModel: Codable, Identifiable, Hashable {
    var id: String { nb }
    let nb: String
    let enTitle: String?
    let arTitle: String?
    var title: String { arTitle ?? enTitle ?? "" }
    let stars: String?
    let arContent: String?
    let enContent: String?
    let mDate: String?
    let year: String?
    let kind: String?
    let season: String?
    let imgObjUrl: String?
    let imgMediumThumbObjUrl: String?
    let imgThumbObjUrl: String?
    let filmRating: String?
    let seriesRating: String?
    let episodeNummer: String?
    let rate: String?
    let duration: String?
    let imdbUrlRef: String?
    let rootSeries: String?
    let trailer: String?
    let skippingDurations: SkippingDurations?
    let subtitles: [Subtitle]?
    let categories: [Category]?
    let videoLikesNumber: String?
    let videoDisLikesNumber: String?
    let videoLanguages: VideoLanguages?
    let videoCommentsNumber: Int?
    let videoViewsNumber: String?
    let directorsInfo: [PersonInfo]?
    let actorsInfo: [PersonInfo]?
    let writersInfo: [PersonInfo]?
    let publishDate: String?
    let episodeDesc: String?
    let url: String?
    let qualities: [Quality]?
}

struct Quality: Codable, Hashable, Identifiable {
    var id: String { url }
    let resolution: String?
    let name: String?
    let url: String
}

struct SkippingDurations: Codable, Hashable {
    let start: [String]?
    let end: [String]?
}

struct Subtitle: Codable, Hashable, Identifiable {
    let id: String?
    let name: String?
    let type: String?
    let `extension`: String?
    let file: String?
}

struct VideoLanguages: Codable, Hashable {
    let audio: [String]?
    let subtitle: [String]?
}

struct PersonInfo: Codable, Hashable, Identifiable {
    let id: String?
    let name: String?
    let imgUrl: String?
}

struct Category: Codable, Hashable, Identifiable {
    let id: String
    let name: String?
    let imgUrl: String?
}

struct CollectionModel: Codable, Hashable, Identifiable {
    let id: String
    let name: String?
    let imgUrl: String?
}

struct Banner: Codable, Hashable {
    let imgObjUrl: String?
    let imgThumb: String?
    let img: String?
    let link: String?

    /// The video id is embedded in the link, e.g. ".../video/en/3112880?show..."
    var videoId: String? {
        guard let link, let match = link.split(separator: "/").last else { return nil }
        return match.split(separator: "?").first.map(String.init)
    }
}

extension Banner: Identifiable {
    var id: String { link ?? imgObjUrl ?? UUID().uuidString }
}

struct VideoGroup: Codable, Hashable, Identifiable {
    let groupID: String
    let name: String?
    let items: [VideoModel]?
    var id: String { groupID }
}

struct VideoComment: Codable, Hashable, Identifiable {
    let id: String
    let userId: String?
    let comment: String?
    let userName: String?
    let date: String?
}

struct TranscodedFile: Codable, Hashable, Identifiable {
    var id: String { url }
    let url: String
    let quality: String?
    let size: Int64?
}

// MARK: - Auth / Account

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    let scope: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

struct UserInfo: Codable {
    let sub: String?
    let email: String?
    let name: String?
}

struct UserSettings: Codable {
    let language: String?
    let parentalLevel: String?
}
