import Foundation
import UIKit

struct DownloadItem: Identifiable, Codable {
    var id: String { videoId }
    let videoId: String
    let title: String
    let thumbnailUrl: String?
    let quality: String
    var progress: Double
    var status: DownloadStatus
    var downloadedBytes: Int64
    var totalBytes: Int64
    var startedAt: Date?

    enum DownloadStatus: String, Codable {
        case pending
        case downloading
        case paused
        case completed
        case failed

        var displayName: String {
            switch self {
            case .pending: return "Waiting"
            case .downloading: return "Downloading"
            case .paused: return "Paused"
            case .completed: return "Completed"
            case .failed: return "Failed"
            }
        }
    }

    var progressText: String {
        switch status {
        case .completed:
            return "Completed"
        case .downloading:
            let downloaded = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
            let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            return "\(downloaded) / \(total)"
        case .failed:
            return "Download failed"
        default:
            return status.displayName
        }
    }
}

struct DownloadedVideo: Codable, Identifiable {
    var id: String { videoId }
    let videoId: String
    let title: String
    let thumbnailUrl: String?
    let quality: String
    let localPath: String
    let downloadedAt: Date
    let fileSize: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var localUrl: URL? {
        let url = URL(fileURLWithPath: localPath)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}

struct WatchLaterItem: Codable, Identifiable {
    var id: String { videoId }
    let videoId: String
    let title: String
    let thumbnailUrl: String?
    let kind: String?
    let addedAt: Date

    var isMovie: Bool {
        kind?.lowercased() == "movie"
    }

    var isSeries: Bool {
        kind?.lowercased() == "series"
    }
}

enum VideoQuality: String, CaseIterable {
    case p1080 = "1080"
    case p720 = "720"
    case p480 = "480"
    case p360 = "360"

    var displayName: String {
        "\(rawValue)p"
    }

    var sortOrder: Int {
        switch self {
        case .p1080: return 0
        case .p720: return 1
        case .p480: return 2
        case .p360: return 3
        }
    }
}

enum SubtitlePosition: String, CaseIterable, Codable {
    case top = "top"
    case middle = "middle"
    case bottom = "bottom"

    var displayName: String {
        switch self {
        case .top: return "Top"
        case .middle: return "Middle"
        case .bottom: return "Bottom"
        }
    }
}

enum SubtitleSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 24
        case .extraLarge: return 32
        }
    }
}

struct PlayerSettings: Codable {
    var selectedQuality: String
    var subtitleEnabled: Bool
    var subtitlePosition: SubtitlePosition
    var subtitleSize: SubtitleSize
    var subtitleLanguage: String?

    static var `default`: PlayerSettings {
        PlayerSettings(
            selectedQuality: "720",
            subtitleEnabled: true,
            subtitlePosition: .bottom,
            subtitleSize: .medium,
            subtitleLanguage: nil
        )
    }
}