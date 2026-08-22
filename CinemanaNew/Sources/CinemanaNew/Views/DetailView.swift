import SwiftUI
import AVKit

struct DetailView: View {
    let video: VideoItem
    @StateObject private var vm = DetailViewModel()
    @State private var selectedEpisode: SeasonEpisode?
    @State private var selectedFile: TranscodedFile?
    @State private var showPlayer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Hero image
                AsyncImage(url: URL(string: video.imgObjUrl ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    default:
                        Color.gray.opacity(0.2)
                            .frame(height: 220)
                            .overlay(Image(systemName: "film").font(.system(size: 60)).foregroundColor(.white.opacity(0.5)))
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 12) {

                    // Title & meta
                    Text(video.displayTitle)
                        .font(.title2).bold()

                    HStack(spacing: 16) {
                        if let year = video.year {
                            Label(year, systemImage: "calendar").font(.subheadline).foregroundColor(.secondary)
                        }
                        if let stars = video.stars {
                            Label(stars, systemImage: "star.fill").font(.subheadline).foregroundColor(.yellow)
                        }
                        Text(video.isMovie ? "Movie" : video.isSeries ? "Series" : "")
                            .font(.caption).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(video.isMovie ? Color.blue : Color.purple)
                            .cornerRadius(6)
                    }

                    // Description
                    if let desc = video.enContent, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // IMDB link
                    if let imdb = video.imdbUrlRef, let url = URL(string: imdb) {
                        Link(destination: url) {
                            Label("View on IMDb", systemImage: "link")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }

                    Divider()

                    // Quality picker & Play
                    if vm.isLoading {
                        ProgressView()
                    } else if !vm.videoFiles.isEmpty {
                        Text("Select Quality")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.videoFiles) { f in
                                    Button(f.resolution ?? "?") {
                                        selectedFile = f
                                        if let fileURL = f.file, URL(string: fileURL) != nil {
                                            showPlayer = true
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(selectedFile?.id == f.id ? .red : .gray)
                                }
                            }
                        }

                        if let file = selectedFile, let rawURL = file.file {
                            let cleanURL = rawURL.replacingOccurrences(of: "\\", with: "")
                            if let url = URL(string: cleanURL) {
                                Button {
                                    showPlayer = true
                                } label: {
                                    Label("Play", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .fullScreenCover(isPresented: $showPlayer) {
                                    VideoPlayerView(url: url)
                                }
                            }
                        }
                    }

                    // Episodes for series
                    if video.isSeries && !vm.episodes.isEmpty {
                        Divider()
                        Text("Episodes")
                            .font(.headline)

                        ForEach(vm.episodes) { ep in
                            HStack {
                                AsyncImage(url: URL(string: ep.imgThumbObjUrl ?? "")) { phase in
                                    if case .success(let img) = phase { img.resizable().scaledToFill() }
                                    else { Color.gray.opacity(0.3) }
                                }
                                .frame(width: 80, height: 50)
                                .clipped().cornerRadius(6)

                                VStack(alignment: .leading) {
                                    Text(ep.displayTitle).font(.subheadline).lineLimit(2)
                                    if let s = ep.season, let e = ep.episodeNummer {
                                        Text("S\(s) E\(e)").font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.loadFiles(videoId: video.id)
            if video.isSeries { vm.loadEpisodes(rootId: video.id) }
        }
    }
}

struct VideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .background(Color.black)
    }
}
