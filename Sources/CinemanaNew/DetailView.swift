import SwiftUI

@MainActor
class DetailVM: ObservableObject {
    @Published var details: VideoDetails?
    @Published var seasons: [Season] = []
    @Published var selectedSeason: Season?
    @Published var streams: [StreamFile] = []
    @Published var subtitles: [SubtitleFile] = []
    @Published var recs: [Video] = []
    @Published var isLoading = false
    private let api = APIService.shared

    func load(_ id: String) async {
        isLoading = true
        if let d = try? await api.fetchVideoDetails(id: id) {
            details = d
            if d.isSeries {
                let s = (try? await api.fetchSeasons(id: id)) ?? []
                seasons = s; selectedSeason = s.first
            } else {
                async let str = (try? api.fetchStreamFiles(id: id)) ?? []
                async let sub = (try? api.fetchSubtitles(id: id)) ?? []
                let (sv, subv) = await (str, sub)
                streams = sv.sorted { $0.qualityOrder > $1.qualityOrder }
                subtitles = subv
            }
            Task {
                recs = (try? await api.fetchRecommendations(movieId: id, movieName: d.displayTitle)) ?? []
            }
            Task { await api.addToHistory(id: id) }
        }
        isLoading = false
    }

    func loadEpisode(_ epId: String) async -> ([StreamFile], [SubtitleFile]) {
        async let str = (try? api.fetchStreamFiles(id: epId)) ?? []
        async let sub = (try? api.fetchSubtitles(id: epId)) ?? []
        return await (str.sorted { $0.qualityOrder > $1.qualityOrder }, sub)
    }
}

struct DetailView: View {
    let videoId: String
    @StateObject private var vm = DetailVM()
    @EnvironmentObject var wl: WatchLaterManager
    @EnvironmentObject var dl: DownloadManager
    @State private var showPlayer = false
    @State private var playerStreams: [StreamFile] = []
    @State private var playerSubs: [SubtitleFile] = []
    @State private var playerTitle = ""
    @State private var showQuality = false
    @State private var showDownload = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            if vm.isLoading { LoadingView() }
            else if let d = vm.details {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        DetailHero(details: d)
                        VStack(spacing: 22) {
                            // Actions
                            HStack(spacing: 10) {
                                Button { play(d) } label: {
                                    Label(d.isSeries ? "Play" : "Watch Now", systemImage: "play.fill")
                                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                                        .background(Color.cRed)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                if !d.isSeries {
                                    Button { showQuality = true } label: {
                                        Image(systemName: "slider.horizontal.3").font(.system(size: 18))
                                            .foregroundColor(.white).frame(width: 50, height: 50).liquidGlass(14)
                                    }
                                    DownloadBtn(videoId: d.id, streams: vm.streams,
                                                title: d.displayTitle, poster: d.poster)
                                }
                                // Watch Later
                                Button {
                                    let v = Video(id: d.id, title: d.title, arabicTitle: d.arabicTitle,
                                                  englishTitle: d.englishTitle, description: nil,
                                                  arabicDescription: nil, poster: d.poster, thumbnail: nil,
                                                  banner: nil, year: d.year, rating: d.rating,
                                                  type: d.type, duration: d.duration, views: nil, isHd: nil, categoryId: nil)
                                    wl.toggle(v)
                                } label: {
                                    Image(systemName: wl.contains(videoId) ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 18)).foregroundColor(wl.contains(videoId) ? .cRed : .white)
                                        .frame(width: 50, height: 50).liquidGlass(14)
                                }
                            }
                            .padding(.horizontal, 16)

                            // Meta
                            HStack(spacing: 12) {
                                if let y = d.year { MetaTag(y) }
                                if let r = d.rating { RatingBadge(rating: r) }
                                if let dur = d.duration { MetaTag(dur) }
                                if d.isSeries { MetaTag("Series", color: .cRed) }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                            // Description
                            if let desc = d.description ?? d.arabicDescription {
                                ExpandDesc(text: desc).padding(.horizontal, 16)
                            }

                            // Cast
                            if let cast = d.actors, !cast.isEmpty {
                                CastRow(cast: cast)
                            }

                            // Seasons
                            if d.isSeries && !vm.seasons.isEmpty {
                                SeasonsView(vm: vm, onEpisode: playEpisode)
                            }

                            // Recommendations
                            if !vm.recs.isEmpty {
                                VStack(spacing: 12) {
                                    SectionHead(title: "You May Also Like")
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(vm.recs) { v in
                                                NavigationLink(destination: DetailView(videoId: v.id)) {
                                                    VideoCard(video: v)
                                                }.buttonStyle(.plain)
                                            }
                                        }.padding(.horizontal, 16)
                                    }
                                }
                            }
                            Spacer(minLength: 100)
                        }.padding(.top, 16)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPlayer) {
            PlayerView(streams: playerStreams, subs: playerSubs, title: playerTitle)
        }
        .sheet(isPresented: $showQuality) {
            QualitySheet(streams: vm.streams, onSelect: { _ in showQuality = false })
                .presentationDetents([.fraction(0.4)])
        }
        .task { await vm.load(videoId) }
    }

    private func play(_ d: VideoDetails) {
        playerStreams = vm.streams; playerSubs = vm.subtitles
        playerTitle = d.displayTitle; showPlayer = true
    }

    private func playEpisode(_ ep: Episode) {
        Task {
            let (str, sub) = await vm.loadEpisode(ep.id)
            playerStreams = str; playerSubs = sub
            playerTitle = ep.displayTitle; showPlayer = true
        }
    }
}

// MARK: - Hero Header
struct DetailHero: View {
    let details: VideoDetails
    var body: some View {
        ZStack(alignment: .bottom) {
            CImg(url: details.posterURL, mode: .fill).frame(height: 400).clipped()
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Color.appBg.opacity(0.7), location: 0.6),
                .init(color: Color.appBg, location: 1)
            ], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                HStack { Spacer() }
                Text(details.displayTitle)
                    .font(.system(size: 26, weight: .black)).foregroundColor(.white).shadow(radius: 6).lineLimit(2)
            }.padding(16)
        }
    }
}

// MARK: - Supporting Views
struct MetaTag: View {
    let text: String; var color: Color = Color.surface
    init(_ text: String, color: Color = Color.surface) { self.text = text; self.color = color }
    var body: some View {
        Text(text).font(.system(size: 12, weight: .semibold)).foregroundColor(.textPri)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color).clipShape(Capsule())
    }
}

struct ExpandDesc: View {
    let text: String
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text).font(.system(size: 14)).foregroundColor(.textSec)
                .lineLimit(expanded ? nil : 3).animation(.easeInOut, value: expanded)
            Button(expanded ? "Show Less" : "Read More") { withAnimation { expanded.toggle() } }
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.cRed)
        }
    }
}

struct CastRow: View {
    let cast: [CastMember]
    var body: some View {
        VStack(spacing: 12) {
            SectionHead(title: "Cast")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(cast) { m in
                        VStack(spacing: 6) {
                            CImg(url: m.photoURL, mode: .fill, radius: 35).frame(width: 70, height: 70)
                            Text(m.name ?? "").font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textPri).lineLimit(2).multilineTextAlignment(.center).frame(width: 70)
                        }
                    }
                }.padding(.horizontal, 16)
            }
        }
    }
}

struct SeasonsView: View {
    @ObservedObject var vm: DetailVM
    let onEpisode: (Episode) -> Void
    var body: some View {
        VStack(spacing: 14) {
            // Season tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.seasons) { s in
                        Button {
                            withAnimation(.spring(response: 0.3)) { vm.selectedSeason = s }
                        } label: {
                            VStack(spacing: 3) {
                                Text(s.displayTitle)
                                    .font(.system(size: 15, weight: vm.selectedSeason?.id == s.id ? .bold : .regular))
                                    .foregroundColor(vm.selectedSeason?.id == s.id ? .white : .textSec)
                                Rectangle().fill(vm.selectedSeason?.id == s.id ? Color.cRed : .clear)
                                    .frame(height: 2).clipShape(Capsule())
                            }.padding(.horizontal, 4).padding(.vertical, 8)
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 16)
            }
            // Episodes
            if let eps = vm.selectedSeason?.episodes {
                VStack(spacing: 0) {
                    ForEach(eps) { ep in
                        EpisodeRow(episode: ep, onPlay: { onEpisode(ep) })
                        if ep.id != eps.last?.id {
                            Divider().background(Color.separator).padding(.leading, 16)
                        }
                    }
                }
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
            }
        }
    }
}

struct EpisodeRow: View {
    let episode: Episode
    let onPlay: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                CImg(url: episode.thumbURL, mode: .fill, radius: 10).frame(width: 120, height: 70)
                Button(action: onPlay) {
                    ZStack {
                        Color.black.opacity(0.35).clipShape(RoundedRectangle(cornerRadius: 10))
                        Circle().fill(Color.cRed).frame(width: 32, height: 32)
                        Image(systemName: "play.fill").font(.system(size: 12)).foregroundColor(.white)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.displayTitle).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPri).lineLimit(2)
                if let d = episode.duration { Text(d).font(.system(size: 12)).foregroundColor(.textSec) }
            }
            Spacer()
        }.padding(12)
    }
}

struct DownloadBtn: View {
    let videoId: String; let streams: [StreamFile]
    let title: String; let poster: String?
    @EnvironmentObject var dl: DownloadManager
    @State private var showSheet = false
    var existing: DownloadItem? { dl.downloads.first { $0.videoId == videoId } }
    var body: some View {
        Button { if existing == nil { showSheet = true } } label: {
            Group {
                if let item = existing {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 2).frame(width: 28, height: 28)
                        Circle().trim(from: 0, to: item.progress)
                            .stroke(item.status.color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 28, height: 28).rotationEffect(.degrees(-90))
                        Image(systemName: item.status.icon).font(.system(size: 11)).foregroundColor(item.status.color)
                    }
                } else {
                    Image(systemName: "arrow.down.circle").font(.system(size: 18)).foregroundColor(.white)
                }
            }
            .frame(width: 50, height: 50).liquidGlass(14)
        }
        .sheet(isPresented: $showSheet) {
            DlQualitySheet(videoId: videoId, title: title, poster: poster, streams: streams)
                .presentationDetents([.fraction(0.5)])
        }
    }
}

struct DlQualitySheet: View {
    let videoId: String; let title: String; let poster: String?; let streams: [StreamFile]
    @EnvironmentObject var dl: DownloadManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        CImg(url: poster.flatMap { URL(string: $0) }, mode: .fill, radius: 10).frame(width: 60, height: 80)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Download").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                            Text(title).font(.system(size: 14)).foregroundColor(.textSec).lineLimit(2)
                        }
                        Spacer()
                    }.padding(16)
                    Divider().background(Color.separator)
                    ForEach(streams, id: \.url) { s in
                        Button {
                            if let url = s.streamURL {
                                dl.start(videoId: videoId, title: title, posterURL: poster,
                                         url: url, quality: s.displayQuality)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(s.displayQuality).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                    if let sz = s.fileSize { Text(sz).font(.system(size: 12)).foregroundColor(.textSec) }
                                }
                                Spacer()
                                Image(systemName: "arrow.down.circle.fill").font(.system(size: 22)).foregroundColor(.cRed)
                            }.padding(16)
                        }.buttonStyle(.plain)
                        Divider().background(Color.separator).padding(.leading, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSec)
                }
            }
        }
    }
}

struct QualitySheet: View {
    let streams: [StreamFile]; let onSelect: (StreamFile) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    ForEach(streams, id: \.url) { s in
                        Button {
                            onSelect(s); dismiss()
                        } label: {
                            HStack {
                                Text(s.displayQuality).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.textMuted)
                            }.padding(16)
                        }.buttonStyle(.plain)
                        Divider().background(Color.separator)
                    }
                }
            }
            .navigationTitle("Select Quality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }.foregroundColor(.cRed)
            }}
        }
    }
}
