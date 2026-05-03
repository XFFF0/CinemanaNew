import Foundation
import Combine
import UIKit

@MainActor
class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var downloads: [DownloadItem] = []
    @Published var downloadedVideos: [DownloadedVideo] = []
    @Published var activeDownloads: [String: URLSessionDownloadTask] = [:]

    private let fileManager = FileManager.default
    private let downloadsDirectory: URL
    private var urlSession: URLSession!

    private let downloadsKey = "com.shabakaty.cinemanaa.downloads"
    private let downloadedVideosKey = "com.shabakaty.cinemanaa.downloadedVideos"

    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        downloadsDirectory = documentsPath.appendingPathComponent("Downloads")

        try? fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: .main)

        loadDownloadedVideos()
        loadActiveDownloads()
    }

    func downloadVideo(_ video: VideoModel, quality: String = "720") {
        Task {
            do {
                let files = try await APIService.shared.getTranscodedFiles(videoId: video.nb)

                guard let selectedFile = files.first(where: { $0.resolution == quality }) ?? files.first else {
                    return
                }

                guard let videoUrlString = selectedFile.videoUrl,
                      let videoUrl = URL(string: videoUrlString) else {
                    return
                }

                let downloadItem = DownloadItem(
                    videoId: video.nb,
                    title: video.title,
                    thumbnailUrl: video.thumbnailUrl,
                    quality: quality,
                    progress: 0,
                    status: .pending,
                    downloadedBytes: 0,
                    totalBytes: 0,
                    startedAt: nil
                )

                self.downloads.append(downloadItem)
                saveDownloads()

                startDownload(url: videoUrl, videoId: video.nb)
            } catch {
                print("Download error: \(error)")
                if let index = self.downloads.firstIndex(where: { $0.videoId == video.nb }) {
                    self.downloads[index].status = .failed
                }
            }
        }
    }

    private func startDownload(url: URL, videoId: String) {
        let task = urlSession.downloadTask(with: url) { [weak self] tempUrl, response, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error {
                    print("Download failed: \(error)")
                    if let index = self.downloads.firstIndex(where: { $0.videoId == videoId }) {
                        self.downloads[index].status = .failed
                    }
                    self.saveDownloads()
                    return
                }

                guard let tempUrl = tempUrl,
                      let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    if let index = self.downloads.firstIndex(where: { $0.videoId == videoId }) {
                        self.downloads[index].status = .failed
                    }
                    self.saveDownloads()
                    return
                }

                let quality = self.downloads.first(where: { $0.videoId == videoId })?.quality ?? "720"
                let destinationUrl = self.downloadsDirectory.appendingPathComponent("\(videoId)_\(quality).mp4")

                do {
                    if self.fileManager.fileExists(atPath: destinationUrl.path) {
                        try self.fileManager.removeItem(at: destinationUrl)
                    }

                    try self.fileManager.moveItem(at: tempUrl, to: destinationUrl)

                    let attributes = try self.fileManager.attributesOfItem(atPath: destinationUrl.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0

                    let video = self.downloads.first(where: { $0.videoId == videoId })

                    let downloadedVideo = DownloadedVideo(
                        videoId: videoId,
                        title: video?.title ?? "",
                        thumbnailUrl: video?.thumbnailUrl,
                        quality: quality,
                        localPath: destinationUrl.path,
                        downloadedAt: Date(),
                        fileSize: fileSize
                    )

                    self.downloadedVideos.append(downloadedVideo)
                    self.saveDownloadedVideos()

                    self.downloads.removeAll { $0.videoId == videoId }
                    self.saveDownloads()

                    print("Download completed: \(destinationUrl.path)")
                } catch {
                    print("Error moving file: \(error)")
                    if let index = self.downloads.firstIndex(where: { $0.videoId == videoId }) {
                        self.downloads[index].status = .failed
                    }
                    self.saveDownloads()
                }
            }
        }

        if let index = downloads.firstIndex(where: { $0.videoId == videoId }) {
            downloads[index].status = .downloading
            downloads[index].startedAt = Date()
            saveDownloads()
        }

        activeDownloads[videoId] = task
        task.resume()

        simulateProgress(videoId: videoId)
    }

    private func simulateProgress(videoId: String) {
        guard let index = downloads.firstIndex(where: { $0.videoId == videoId }) else { return }

        var progress: Double = 0
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self,
                      let idx = self.downloads.firstIndex(where: { $0.videoId == videoId }) else {
                    timer.invalidate()
                    return
                }

                if self.downloads[idx].status == .downloading {
                    progress += Double.random(in: 0.02...0.08)
                    if progress >= 1.0 {
                        progress = 0.99
                    }

                    self.downloads[idx].progress = progress * 100
                    self.downloads[idx].totalBytes = Int64.random(in: 500_000_000...2_000_000_000)
                    self.downloads[idx].downloadedBytes = Int64(Double(self.downloads[idx].totalBytes) * progress)
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    func cancelDownload(videoId: String) {
        activeDownloads[videoId]?.cancel()
        activeDownloads.removeValue(forKey: videoId)
        downloads.removeAll { $0.videoId == videoId }
        saveDownloads()
    }

    func pauseDownload(videoId: String) {
        activeDownloads[videoId]?.suspend()
        if let index = downloads.firstIndex(where: { $0.videoId == videoId }) {
            downloads[index].status = .paused
            saveDownloads()
        }
    }

    func resumeDownload(videoId: String) {
        activeDownloads[videoId]?.resume()
        if let index = downloads.firstIndex(where: { $0.videoId == videoId }) {
            downloads[index].status = .downloading
            saveDownloads()
        }
    }

    func deleteDownload(_ video: DownloadedVideo) {
        try? fileManager.removeItem(atPath: video.localPath)
        downloadedVideos.removeAll { $0.videoId == video.videoId }
        saveDownloadedVideos()
    }

    func getLocalVideoUrl(_ video: DownloadedVideo) -> URL? {
        let url = URL(fileURLWithPath: video.localPath)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func isDownloaded(videoId: String) -> Bool {
        downloadedVideos.contains { $0.videoId == videoId }
    }

    func getDownloadedVideo(videoId: String) -> DownloadedVideo? {
        downloadedVideos.first { $0.videoId == videoId }
    }

    func getDownloadProgress(videoId: String) -> Double? {
        downloads.first { $0.videoId == videoId }?.progress
    }

    private func loadDownloadedVideos() {
        if let data = UserDefaults.standard.data(forKey: downloadedVideosKey),
           let videos = try? JSONDecoder().decode([DownloadedVideo].self, from: data) {
            downloadedVideos = videos.filter { FileManager.default.fileExists(atPath: $0.localPath) }
            saveDownloadedVideos()
        }
    }

    private func saveDownloadedVideos() {
        if let data = try? JSONEncoder().encode(downloadedVideos) {
            UserDefaults.standard.set(data, forKey: downloadedVideosKey)
        }
    }

    private func loadActiveDownloads() {
        if let data = UserDefaults.standard.data(forKey: downloadsKey),
           let items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = items.filter { $0.status != .completed && $0.status != .failed }
        }
    }

    private func saveDownloads() {
        let itemsToSave = downloads.filter { $0.status != .completed && $0.status != .failed }
        if let data = try? JSONEncoder().encode(itemsToSave) {
            UserDefaults.standard.set(data, forKey: downloadsKey)
        }
    }
}