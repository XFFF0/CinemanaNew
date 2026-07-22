import SwiftUI
import AVKit

/// Replaces the Android app's CinemanaPlayerView (ExoPlayer wrapper).
/// Supports the skip-intro/recap ranges documented in the RE report (§5.4).
struct VideoPlayerView: View {
    let url: URL
    let skip: SkippingDurations?

    @State private var player: AVPlayer
    @State private var showSkipButton = false
    @State private var skipRanges: [(start: Double, end: Double)] = []

    init(url: URL, skip: SkippingDurations?) {
        self.url = url
        self.skip = skip
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VideoPlayer(player: player)
                .onAppear {
                    skipRanges = parseSkipRanges(skip)
                    player.play()
                    addPeriodicObserver()
                }
                .onDisappear { player.pause() }

            if showSkipButton {
                Button("تخطي") {
                    if let range = currentSkipRange() {
                        let target = CMTime(seconds: range.end, preferredTimescale: 1)
                        player.seek(to: target)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding()
            }
        }
        .ignoresSafeArea()
    }

    private func parseSkipRanges(_ skip: SkippingDurations?) -> [(Double, Double)] {
        guard let skip, let starts = skip.start, let ends = skip.end else { return [] }
        return zip(starts, ends).compactMap { s, e in
            guard let sd = Double(s), let ed = Double(e) else { return nil }
            return (sd, ed)
        }
    }

    private func currentSkipRange() -> (start: Double, end: Double)? {
        let current = player.currentTime().seconds
        return skipRanges.first { current >= $0.start && current < $0.end }
    }

    private func addPeriodicObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: 1)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
            showSkipButton = currentSkipRange() != nil
        }
    }
}
