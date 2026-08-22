import SwiftUI
import AVKit

struct DetailView: View {
    let video: VideoItem
    @StateObject private var vm = DetailViewModel()
    @State private var selectedFileID: String?
    @State private var playerURL: URL?
    @State private var showPlayer = false
    @State private var showComments = false
    @State private var commentText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                VStack(alignment: .leading, spacing: 16) {
                    titleSection
                    Divider()
                    qualitySection
                    if video.isSeries && !vm.episodes.isEmpty {
                        Divider(); episodesSection
                    }
                    if !vm.relatedVideos.isEmpty {
                        Divider(); relatedSection
                    }
                    Divider(); commentsSection
                }.padding()
            }
        }
        .navigationTitle(video.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPlayer) {
            if let url = playerURL { VideoPlayerView(url: url) }
        }
        .onAppear { vm.loadAll(video: video) }
    }

    // MARK: - Hero
    @ViewBuilder var heroSection: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: video.fullURL ?? video.medURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFit()
                default: Color(.systemGray5).frame(height: 250)
                    .overlay(Image(systemName: "film").font(.system(size: 60)).foregroundColor(.secondary))
                }
            }.frame(maxWidth: .infinity)

            LinearGradient(colors: [.clear, .black.opacity(0.75)],
                           startPoint: .top, endPoint: .bottom)

            Button {
                if playerURL == nil, let f = vm.videoFiles.first {
                    playerURL = f.streamURL; selectedFileID = f.id
                }
                if !vm.videoFiles.isEmpty { showPlayer = true }
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(vm.videoFiles.isEmpty ? Color.white.opacity(0.4) : .white)
                    .shadow(color: .black.opacity(0.5), radius: 8)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Title
    @ViewBuilder var titleSection: some View {
        Text(video.displayTitle).font(.title2).bold()

        HStack(spacing: 10) {
            if let yr = video.year {
                Label(yr, systemImage: "calendar").font(.subheadline).foregroundColor(.secondary)
            }
            if let score = video.imdbScore {
                IMDbBadge(score: score)
            }
            TypeBadge(isMovie: video.isMovie, isSeries: video.isSeries)
        }

        if let desc = video.enContent, !desc.isEmpty {
            Text(desc).font(.body).foregroundColor(.secondary)
        }

        HStack(spacing: 16) {
            if let url = video.imdbURL {
                Link(destination: url) {
                    Label("IMDb", systemImage: "link").font(.subheadline).foregroundColor(.orange)
                }
            }
            if let tURL = video.trailerURL {
                Link(destination: tURL) {
                    Label("Trailer", systemImage: "play.rectangle").font(.subheadline).foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Quality
    @ViewBuilder var qualitySection: some View {
        if vm.isLoading {
            HStack { ProgressView(); Text("Loading sources…").foregroundColor(.secondary) }
        } else if vm.videoFiles.isEmpty {
            Label("No video sources", systemImage: "xmark.circle").foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quality").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.videoFiles) { file in
                            Button {
                                selectedFileID = file.id
                                playerURL = file.streamURL
                            } label: {
                                Text(file.resolution ?? "?")
                                    .font(.subheadline).bold()
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedFileID == file.id ? Color.red : Color(.systemGray5))
                                    .foregroundColor(selectedFileID == file.id ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                Button {
                    if playerURL == nil, let f = vm.videoFiles.first {
                        playerURL = f.streamURL; selectedFileID = f.id
                    }
                    showPlayer = true
                } label: {
                    Label("Play Now", systemImage: "play.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.red).foregroundColor(.white).cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Episodes
    @ViewBuilder var episodesSection: some View {
        Text("Episodes (\(vm.episodes.count))").font(.headline)
        ForEach(vm.episodes) { ep in
            Button {
                vm.loadFiles(videoId: ep.id)
                selectedFileID = nil; playerURL = nil
            } label: {
                HStack(spacing: 10) {
                    AsyncImage(url: ep.thumbURL) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Color(.systemGray5)
                            .overlay(Image(systemName: "play.rectangle").foregroundColor(.secondary))
                        }
                    }.frame(width: 90, height: 55).clipped().cornerRadius(6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ep.displayTitle).font(.subheadline).lineLimit(2).foregroundColor(.primary)
                        if let s = ep.season, let e = ep.episodeNummer {
                            Text("S\(s) · E\(e)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "play.circle").foregroundColor(.red).font(.title2)
                }
            }.buttonStyle(.plain)
            Divider()
        }
    }

    // MARK: - Related
    @ViewBuilder var relatedSection: some View {
        Text("More Like This").font(.headline)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(vm.relatedVideos) { item in
                    NavigationLink(destination: DetailView(video: item)) {
                        PosterCard(item: item)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Comments
    @ViewBuilder var commentsSection: some View {
        Button { withAnimation { showComments.toggle() } } label: {
            HStack {
                Text("Comments (\(vm.comments.count))").font(.headline)
                Spacer()
                Image(systemName: showComments ? "chevron.up" : "chevron.down").foregroundColor(.secondary)
            }
        }.buttonStyle(.plain)

        if showComments {
            if vm.isLoadingComments {
                ProgressView()
            } else {
                ForEach(vm.comments.prefix(15)) { c in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(c.userName ?? "User").font(.caption).bold()
                            Spacer()
                            if let d = c.itemDate { Text(d).font(.caption2).foregroundColor(.secondary) }
                        }
                        Text(c.comment ?? "").font(.subheadline)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
                if vm.comments.isEmpty {
                    Text("No comments yet").foregroundColor(.secondary).font(.subheadline)
                }
            }
        }
    }
}

// MARK: - Player
struct VideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let player = player {
                VideoPlayer(player: player).ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ProgressView().tint(.white).scaleEffect(1.5)
            }
            Button { player?.pause(); dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title).foregroundColor(.white).shadow(radius: 4).padding(20)
            }
        }
        .onAppear { player = AVPlayer(url: url) }
    }
}
