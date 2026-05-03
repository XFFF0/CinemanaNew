import Foundation

@MainActor
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    @Published var downloads: [DownloadItem] = []
    private var tasks: [String: URLSessionDownloadTask] = [:]
    private var resumeData: [String: Data] = [:]
    private var bgSession: URLSession!
    private let key = "downloads_v2"

    private override init() {
        super.init()
        let cfg = URLSessionConfiguration.background(withIdentifier: "com.shabakaty.cinemanaa.dl")
        cfg.isDiscretionary = false
        bgSession = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
        load()
    }

    // MARK: - Public API
    func start(videoId: String, title: String, posterURL: String?, url: URL, quality: String) {
        let itemId = "\(videoId)_\(quality)"
        guard !downloads.contains(where: { $0.id == itemId }) else { return }

        let item = DownloadItem(
            id: itemId, videoId: videoId, title: title,
            posterURL: posterURL, quality: quality,
            progress: 0, downloadedBytes: 0, totalBytes: 0,
            status: .downloading, localPath: nil, addedAt: Date()
        )
        downloads.insert(item, at: 0)
        save()

        let task = bgSession.downloadTask(with: url)
        task.taskDescription = itemId
        tasks[itemId] = task
        task.resume()
    }

    func pause(_ id: String) {
        tasks[id]?.cancel(byProducingResumeData: { [weak self] data in
            DispatchQueue.main.async {
                self?.resumeData[id] = data
                self?.setStatus(id, .paused)
            }
        })
        tasks.removeValue(forKey: id)
    }

    func resume(_ id: String) {
        if let data = resumeData[id] {
            resumeData.removeValue(forKey: id)
            let task = bgSession.downloadTask(withResumeData: data)
            task.taskDescription = id
            tasks[id] = task
            setStatus(id, .downloading)
            task.resume()
        }
    }

    func cancel(_ id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
        resumeData.removeValue(forKey: id)
        if let i = downloads.firstIndex(where: { $0.id == id }) {
            if let path = downloads[i].localPath { try? FileManager.default.removeItem(atPath: path) }
            downloads.remove(at: i)
        }
        save()
    }

    func localURL(_ id: String) -> URL? {
        downloads.first(where: { $0.id == id })?.localPath.map { URL(fileURLWithPath: $0) }
    }

    var active: [DownloadItem] { downloads.filter { $0.status != .completed } }
    var completed: [DownloadItem] { downloads.filter { $0.status == .completed } }

    // MARK: - Private
    private func setStatus(_ id: String, _ status: DownloadItem.DownloadStatus) {
        if let i = downloads.firstIndex(where: { $0.id == id }) {
            downloads[i].status = status
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([DownloadItem].self, from: data) else { return }
        downloads = items.map {
            var m = $0; if m.status == .downloading { m.status = .paused }; return m
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate, URLSessionDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let id = downloadTask.taskDescription else { return }
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(id).mp4")
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: location, to: dest)
        DispatchQueue.main.async {
            if let i = self.downloads.firstIndex(where: { $0.id == id }) {
                self.downloads[i].status = .completed
                self.downloads[i].progress = 1.0
                self.downloads[i].localPath = dest.path
                self.tasks.removeValue(forKey: id)
                self.save()
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let id = downloadTask.taskDescription else { return }
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        DispatchQueue.main.async {
            if let i = self.downloads.firstIndex(where: { $0.id == id }) {
                self.downloads[i].progress = progress
                self.downloads[i].downloadedBytes = totalBytesWritten
                self.downloads[i].totalBytes = totalBytesExpectedToWrite
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let id = task.taskDescription else { return }
        let ns = error as NSError
        guard ns.code != NSURLErrorCancelled else { return }
        DispatchQueue.main.async { self.setStatus(id, .failed) }
    }
}
