import Foundation

@MainActor
class PlayerSettingsManager: ObservableObject {
    static let shared = PlayerSettingsManager()

    @Published var settings: PlayerSettings {
        didSet {
            saveSettings()
        }
    }

    private let key = "com.shabakaty.cinemanaa.playerSettings"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(PlayerSettings.self, from: data) {
            settings = saved
        } else {
            settings = .default
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func setQuality(_ quality: String) {
        settings.selectedQuality = quality
    }

    func setSubtitleEnabled(_ enabled: Bool) {
        settings.subtitleEnabled = enabled
    }

    func setSubtitlePosition(_ position: SubtitlePosition) {
        settings.subtitlePosition = position
    }

    func setSubtitleSize(_ size: SubtitleSize) {
        settings.subtitleSize = size
    }

    func setSubtitleLanguage(_ language: String?) {
        settings.subtitleLanguage = language
    }

    func resetToDefaults() {
        settings = .default
    }
}