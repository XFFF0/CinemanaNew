import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                if vm.isLoading && vm.banners.isEmpty && vm.newlyVideos.isEmpty {
                    ProgressView().padding(80)
                } else {
                    LazyVStack(alignment: .leading, spacing: 28) {

                        // Featured banner
                        if !vm.banners.isEmpty {
                            SectionTitle("Featured")
                            BannerCarousel(items: vm.banners)
                        }

                        // New Releases
                        if !vm.newlyVideos.isEmpty {
                            SectionTitle("New Releases")
                            PosterRow(items: vm.newlyVideos)
                        }

                        // Movies
                        if !vm.moviesPage1.isEmpty {
                            SectionTitle("Movies")
                            PosterRow(items: vm.moviesPage1)
                        }

                        // Series
                        if !vm.seriesPage1.isEmpty {
                            SectionTitle("Series")
                            PosterRow(items: vm.seriesPage1)
                        }

                        // More Movies
                        if !vm.moviesPage2.isEmpty {
                            SectionTitle("More Movies")
                            PosterRow(items: vm.moviesPage2)
                        }

                        // Groups from API
                        ForEach(vm.groups) { grp in
                            if let items = vm.groupVideos[grp.id], !items.isEmpty {
                                SectionTitle(grp.displayTitle)
                                PosterRow(items: items)
                            }
                        }

                        // Empty state
                        if vm.banners.isEmpty && vm.moviesPage1.isEmpty && !vm.isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 50)).foregroundColor(.secondary)
                                Text("Could not load content").foregroundColor(.secondary)
                                Button("Retry") { vm.loadHome() }
                                    .buttonStyle(.borderedProminent).tint(.red)
                            }
                            .frame(maxWidth: .infinity).padding(60)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Cinemana New")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { vm.loadHome() }
        }
    }
}

// MARK: - Reusable Components
struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.title2).bold().padding(.horizontal)
    }
}

struct BannerCarousel: View {
    let items: [VideoItem]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items.prefix(15)) { item in
                    NavigationLink(destination: DetailView(video: item)) {
                        BannerCard(item: item)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal)
        }
    }
}

struct PosterRow: View {
    let items: [VideoItem]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items) { item in
                    NavigationLink(destination: DetailView(video: item)) {
                        PosterCard(item: item)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal)
        }
    }
}

struct BannerCard: View {
    let item: VideoItem
    var body: some View {
        ZStack(alignment: .bottom) {
            CachedImage(url: item.fullURL ?? item.medURL, width: 260, height: 150)
            LinearGradient(colors: [.clear, .black.opacity(0.85)],
                           startPoint: .center, endPoint: .bottom)
            Text(item.displayTitle)
                .font(.caption).bold().foregroundColor(.white)
                .lineLimit(1).padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 260, height: 150)
        .cornerRadius(12).shadow(radius: 4)
    }
}

struct PosterCard: View {
    let item: VideoItem
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            CachedImage(url: item.thumbURL ?? item.medURL, width: 110, height: 160)
                .cornerRadius(8)
            Text(item.displayTitle)
                .font(.caption).bold().lineLimit(2)
                .frame(width: 110, alignment: .leading)
            if let yr = item.year {
                Text(yr).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

struct CachedImage: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img): img.resizable().scaledToFill()
            case .failure: Color(.systemGray5)
                    .overlay(Image(systemName: "film").foregroundColor(.secondary))
            default: Color(.systemGray5).overlay(ProgressView())
            }
        }
        .frame(width: width, height: height).clipped()
    }
}
