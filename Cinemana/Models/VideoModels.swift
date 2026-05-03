import Foundation

struct VideoModel: Codable, Identifiable, Hashable {
    var id: String { nb }
    let nb: String
    let arTitle: String?
    let enTitle: String?
    let customArTitle: String?
    let customEnTitle: String?
    let arContent: String?
    let enContent: String?
    let kind: String?
    let year: String?
    let duration: String?
    let stars: String?
    let rate: String?
    let filmRating: String?
    let seriesRating: String?
    let imgObjUrl: String?
    let imgMediumThumbObjUrl: String?
    let imgThumbObjUrl: String?
    let trailer: String?
    let imdbUrlRef: String?
    let episodeFlag: String?
    let episodeNummer: String?
    let season: String?
    let rootSeries: String?
    let listId: String?
    let itemDate: String?
    let publishDate: String?
    let videoLikesNumber: String?
    let videoDisLikesNumber: String?
    let videoViewsNumber: String?
    let videoCommentsNumber: Int?
    let showComments: Bool?
    let castable: String?
    let isSpecial: String?
    let hasIntroSkipping: Bool?
    let introSkipping: [String]?
    let skippingDurations: [String: String]?
    let translations: [TranslationInfo]?
    let categories: [Category]?
    let actorsInfo: [StaffInfo]?
    let directorsInfo: [StaffInfo]?
    let writersInfo: [StaffInfo]?
    let videoLanguages: [String: String]?

    var title: String {
        customArTitle ?? customEnTitle ?? arTitle ?? enTitle ?? ""
    }

    var titleEn: String {
        customEnTitle ?? enTitle ?? ""
    }

    var thumbnailUrl: String? {
        imgMediumThumbObjUrl ?? imgThumbObjUrl ?? imgObjUrl
    }

    var posterUrl: String? {
        imgObjUrl
    }

    var isMovie: Bool {
        kind?.lowercased() == "movie"
    }

    var isSeries: Bool {
        kind?.lowercased() == "series"
    }

    var formattedDuration: String {
        guard let duration = duration else { return "" }
        return duration
    }

    var rating: String {
        if let rate = rate, !rate.isEmpty {
            return rate
        }
        if let filmRating = filmRating, !filmRating.isEmpty {
            return filmRating
        }
        if let seriesRating = seriesRating, !seriesRating.isEmpty {
            return seriesRating
        }
        return ""
    }
}

struct TranslationInfo: Codable, Hashable {
    let language: String?
    let url: String?
    let languageName: String?
}

struct Category: Codable, Hashable {
    let nb: String?
    let name: String?
    let nameEn: String?

    var displayName: String {
        nameEn ?? name ?? ""
    }
}

struct StaffInfo: Codable, Hashable {
    let nb: String?
    let name: String?
    let picture: String?
    let role: String?
}

struct TranscodeFile: Codable, Identifiable {
    var id: String { "\(resolution ?? "")_\(container ?? "")" }
    let name: String?
    let resolution: String?
    let container: String?
    let transcoddedFileName: String?
    let videoUrl: String?

    var displayName: String {
        if let res = resolution {
            return "\(res)p"
        }
        return name ?? "Unknown"
    }
}

struct VideosGroup: Codable, Identifiable {
    var id: String { listId ?? UUID().uuidString }
    let listId: String?
    let groupName: String?
    let groupNameEn: String?
    let videos: [VideoModel]?

    var displayName: String {
        groupNameEn ?? groupName ?? ""
    }
}

struct HomeGroupsResponse: Codable {
    let groups: [VideosGroup]?
}

struct CollectionItem: Codable, Identifiable {
    var id: String { nb ?? UUID().uuidString }
    let nb: String?
    let name: String?
    let nameEn: String?
    let imageUrl: String?
    let descriptionText: String?
    let descriptionEn: String?
    let videos: [VideoModel]?

    var displayName: String {
        nameEn ?? name ?? ""
    }
}

struct NewCategoryItem: Codable, Identifiable {
    var id: String { nb ?? UUID().uuidString }
    let nb: String?
    let name: String?
    let nameEn: String?
    let imageUrl: String?

    var displayName: String {
        nameEn ?? name ?? ""
    }
}

struct SearchYearItem: Codable, Identifiable {
    var id: String { year ?? UUID().uuidString }
    let year: String?
}

struct VideoWatchStatus: Codable {
    let watched: Bool?
    let currentPosition: Int?
    let totalDuration: Int?
}

struct UserSettings: Codable {
    let language: String?
    let translationEnabled: Bool?
    let translationSize: String?
    let translationPosition: String?
}