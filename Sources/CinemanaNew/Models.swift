import Foundation
import SwiftUI

// MARK: - Auth
struct AuthResponse: Codable {
    let accessToken: String?
    let tokenType: String?
    let expiresIn: Int?
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

struct UserInfo: Codable {
    let id: String?
    let name: String?
    let email: String?
    let picture: String?
    let level: Int?
}

// MARK: - Video (flexible decoder)
struct Video: Codable, Identifiable, Hashable {
    var id: String
    var title: String?
    var arabicTitle: String?
    var englishTitle: String?
    var description: String?
    var arabicDescription: String?
    var poster: String?
    var thumbnail: String?
    var banner: String?
    var year: String?
    var rating: Double?
    var type: String?
    var duration: String?
    var views: String?
    var isHd: String?
    var categoryId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, poster, thumbnail, banner, year, rating, type, duration, views
        case arabicTitle = "arabic_title"
        case englishTitle = "english_title"
        case arabicDescription = "arabic_description"
        case isHd = "is_hd"
        case categoryId = "category_id"
    }

    // Handle id as Int or String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        }
        title = try? c.decode(String.self, forKey: .title)
        arabicTitle = try? c.decode(String.self, forKey: .arabicTitle)
        englishTitle = try? c.decode(String.self, forKey: .englishTitle)
        description = try? c.decode(String.self, forKey: .description)
        arabicDescription = try? c.decode(String.self, forKey: .arabicDescription)
        poster = try? c.decode(String.self, forKey: .poster)
        thumbnail = try? c.decode(String.self, forKey: .thumbnail)
        banner = try? c.decode(String.self, forKey: .banner)
        year = try? c.decode(String.self, forKey: .year)
        if let d = try? c.decode(Double.self, forKey: .rating) { rating = d }
        else if let s = try? c.decode(String.self, forKey: .rating) { rating = Double(s) }
        else { rating = nil }
        type = try? c.decode(String.self, forKey: .type)
        duration = try? c.decode(String.self, forKey: .duration)
        views = try? c.decode(String.self, forKey: .views)
        isHd = try? c.decode(String.self, forKey: .isHd)
        categoryId = try? c.decode(String.self, forKey: .categoryId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(title, forKey: .title)
    }

    var displayTitle: String { englishTitle ?? arabicTitle ?? title ?? "Unknown" }
    var isSeries: Bool { type?.lowercased().contains("serie") == true || type == "2" || type == "s" }
    var posterURL: URL? { (poster ?? thumbnail).flatMap { URL(string: $0) } }
    var hdFlag: Bool { isHd == "1" || isHd == "true" }

    static func == (l: Video, r: Video) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

// MARK: - Banner
struct Banner: Codable, Identifiable {
    var id: String
    var image: String?
    var videoId: String?
    var title: String?

    enum CodingKeys: String, CodingKey {
        case id, image, title
        case videoId = "video_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .id) { id = String(i) }
        else { id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString }
        image = try? c.decode(String.self, forKey: .image)
        videoId = try? c.decode(String.self, forKey: .videoId)
        title = try? c.decode(String.self, forKey: .title)
    }

    var imageURL: URL? { image.flatMap { URL(string: $0) } }
}

// MARK: - VideoGroup
struct VideoGroup: Codable, Identifiable {
    var id: String
    var title: String?
    var arabicTitle: String?
    var englishTitle: String?
    var videos: [Video]?

    enum CodingKeys: String, CodingKey {
        case id, title, videos
        case arabicTitle = "arabic_title"
        case englishTitle = "english_title"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .id) { id = String(i) }
        else { id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString }
        title = try? c.decode(String.self, forKey: .title)
        arabicTitle = try? c.decode(String.self, forKey: .arabicTitle)
        englishTitle = try? c.decode(String.self, forKey: .englishTitle)
        videos = try? c.decode([Video].self, forKey: .videos)
    }

    var displayTitle: String { englishTitle ?? arabicTitle ?? title ?? "" }
}

// MARK: - VideoDetails
struct VideoDetails: Codable, Identifiable {
    var id: String
    var title: String?
    var arabicTitle: String?
    var englishTitle: String?
    var description: String?
    var arabicDescription: String?
    var poster: String?
    var banner: String?
    var year: String?
    var rating: Double?
    var type: String?
    var duration: String?
    var actors: [CastMember]?
    var directors: [CastMember]?
    var categories: [CategoryItem]?
    var trailer: String?
    var imdb: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, poster, banner, year, rating, type, duration, actors, directors, categories, trailer, imdb
        case arabicTitle = "arabic_title"
        case englishTitle = "english_title"
        case arabicDescription = "arabic_description"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .id) { id = String(i) }
        else { id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString }
        title = try? c.decode(String.self, forKey: .title)
        arabicTitle = try? c.decode(String.self, forKey: .arabicTitle)
        englishTitle = try? c.decode(String.self, forKey: .englishTitle)
        description = try? c.decode(String.self, forKey: .description)
        arabicDescription = try? c.decode(String.self, forKey: .arabicDescription)
        poster = try? c.decode(String.self, forKey: .poster)
        banner = try? c.decode(String.self, forKey: .banner)
        year = try? c.decode(String.self, forKey: .year)
        if let d = try? c.decode(Double.self, forKey: .rating) { rating = d }
        else if let s = try? c.decode(String.self, forKey: .rating) { rating = Double(s) }
        else { rating = nil }
        type = try? c.decode(String.self, forKey: .type)
        duration = try? c.decode(String.self, forKey: .duration)
        actors = try? c.decode([CastMember].self, forKey: .actors)
        directors = try? c.decode([CastMember].self, forKey: .directors)
        categories = try? c.decode([CategoryItem].self, forKey: .categories)
        trailer = try? c.decode(String.self, forKey: .trailer)
        imdb = try? c.decode(String.self, forKey: .imdb)
    }

    var displayTitle: String { englishTitle ?? arabicTitle ?? title ?? "Unknown" }
    var isSeries: Bool { type == "2" || type?.lowercased().contains("serie") == true }
    var posterURL: URL? { (poster ?? banner).flatMap { URL(string: $0) } }
}

// MARK: - Season & Episode
struct Season: Codable, Identifiable, Hashable {
    var id: String
    var number: Int?
    var title: String?
    var episodes: [Episode]?

    enum CodingKeys: String, CodingKey {
        case id, title, episodes
        case number = "season_number"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .id) { id = String(i) }
        else { id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString }
        if let n = try? c.decode(Int.self, forKey: .number) { number = n }
        else if let s = try? c.decode(String.self, forKey: .number) { number = Int(s) }
        title = try? c.decode(String.self, forKey: .title)
        episodes = try? c.decode([Episode].self, forKey: .episodes)
    }

    var displayTitle: String { number.map { "Season \($0)" } ?? title ?? "Season" }
    static func == (l: Season, r: Season) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

struct Episode: Codable, Identifiable, Hashable {
    var id: String
    var number: Int?
    var title: String?
    var arabicTitle: String?
    var englishTitle: String?
    var thumbnail: String?
    var duration: String?
    var description: String?

    enum CodingKeys: String, CodingKey {
        case id, title, thumbnail, duration, description
        case number = "episode_number"
        case arabicTitle = "arabic_title"
        case englishTitle = "english_title"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .id) { id = String(i) }
        else { id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString }
        if let n = try? c.decode(Int.self, forKey: .number) { number = n }
        else if let s = try? c.decode(String.self, forKey: .number) { number = Int(s) }
        title = try? c.decode(String.self, forKey: .title)
        arabicTitle = try? c.decode(String.self, forKey: .arabicTitle)
        englishTitle = try? c.decode(String.self, forKey: .englishTitle)
        thumbnail = try? c.decode(String.self, forKey: .thumbnail)
        duration = try? c.decode(String.self, forKey: .duration)
        description = try? c.decode(String.self, forKey: .description)
    }

    var displayTitle: String {
        let n = number.map { "E\($0) " } ?? ""
        return n + (englishTitle ?? arabicTitle ?? title ?? "Episode")
    }
    var thumbURL: URL? { thumbnail.flatMap { URL(string: $0) } }
    static func == (l: Episode, r: Episode) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

// MARK: - Stream
struct StreamFile: Codable, Identifiable {
    var id: String { url }
    var url: String
    var quality: String?
    var resolution: String?
    var fileSize: String?

    enum CodingKeys: String, CodingKey {
        case url, quality, resolution
        case fileSize = "file_size"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        url = (try? c.decode(String.self, forKey: .url)) ?? ""
        quality = try? c.decode(String.self, forKey: .quality)
        resolution = try? c.decode(String.self, forKey: .resolution)
        fileSize = try? c.decode(String.self, forKey: .fileSize)
    }

    var displayQuality: String { quality ?? resolution ?? "Auto" }
    var streamURL: URL? { URL(string: url) }

    var qualityOrder: Int {
        let q = (quality ?? resolution ?? "").lowercased()
        if q.contains("1080") { return 5 }
        if q.contains("720") { return 4 }
        if q.contains("480") { return 3 }
        if q.contains("360") { return 2 }
        if q.contains("240") { return 1 }
        return 0
    }
}

// MARK: - Subtitle
struct SubtitleFile: Codable, Identifiable {
    var id: String { url }
    var url: String
    var language: String?
    var label: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        url = (try? c.decode(String.self, forKey: .url)) ?? ""
        language = try? c.decode(String.self, forKey: .language)
        label = try? c.decode(String.self, forKey: .label)
    }

    enum CodingKeys: String, CodingKey { case url, language, label }
    var displayName: String { label ?? language ?? "Subtitle" }
    var subURL: URL? { URL(string: url) }
}

// MARK: - Category
struct CategoryItem: Codable, Identifiable {
    var id: String
    var name: String?
    var arabicName: String?
    var englishName: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case arabicName = "arabic_name"
        case englishName = "english_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .id) { id = String(i) }
        else { id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString }
        name = try? c.decode(String.self, forKey: .name)
        arabicName = try? c.decode(String.self, forKey: .arabicName)
        englishName = try? c.decode(String.self, forKey: .englishName)
    }

    var displayName: String { englishName ?? arabicName ?? name ?? "" }
}

struct CastMember: Codable, Identifiable {
    var id: String
    var name: String?
    var photo: String?
    var role: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? c.decode(Int.self, forKey: .id) { id = String(i) }
        else { id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString }
        name = try? c.decode(String.self, forKey: .name)
        photo = try? c.decode(String.self, forKey: .photo)
        role = try? c.decode(String.self, forKey: .role)
    }

    enum CodingKeys: String, CodingKey { case id, name, photo, role }
    var photoURL: URL? { photo.flatMap { URL(string: $0) } }
}

// MARK: - Download
struct DownloadItem: Identifiable, Codable {
    let id: String
    let videoId: String
    let title: String
    let posterURL: String?
    let quality: String
    var progress: Double
    var downloadedBytes: Int64
    var totalBytes: Int64
    var status: DownloadStatus
    var localPath: String?
    let addedAt: Date

    enum DownloadStatus: String, Codable {
        case queued, downloading, paused, completed, failed
        var color: Color {
            switch self {
            case .queued: return .gray
            case .downloading: return .blue
            case .paused: return .orange
            case .completed: return .green
            case .failed: return .red
            }
        }
        var icon: String {
            switch self {
            case .queued: return "clock"
            case .downloading: return "arrow.down.circle.fill"
            case .paused: return "pause.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.circle.fill"
            }
        }
    }

    var posterImage: URL? { posterURL.flatMap { URL(string: $0) } }
    var progressText: String {
        if totalBytes > 0 {
            let dl = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
            let tot = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            return "\(dl) / \(tot)"
        }
        return ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
    }
}

// MARK: - Watch Later
struct WatchLaterItem: Identifiable, Codable {
    let id: String
    let videoId: String
    let title: String
    let posterURL: String?
    let type: String?
    let year: String?
    let addedAt: Date
    var poster: URL? { posterURL.flatMap { URL(string: $0) } }
}

// MARK: - Subtitle Settings
struct SubtitleSettings: Codable {
    var isEnabled: Bool = true
    var fontSize: CGFloat = 18
    var fontName: String = "GeezaPro-Bold"
    var textColor: String = "#FFFFFF"
    var bgOpacity: Double = 0.6
    var position: Position = .bottom
    var offsetY: CGFloat = 30

    enum Position: String, Codable, CaseIterable {
        case top = "Top"
        case center = "Center"
        case bottom = "Bottom"
    }
}

// MARK: - History Entry (for addToHistory)
struct HistoryEntry: Codable {
    let videoId: String
    let watchedSeconds: Int
}
