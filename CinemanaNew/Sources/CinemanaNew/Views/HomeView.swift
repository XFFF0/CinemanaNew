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

                        if !vm.banners.isEmpty {
                            SectionTitle("Featured")
                            BannerCarousel(items: vm.banners)
                        }

                        if !vm.newlyVideos.isEmpty {
                            SectionTitle("New Releases")
                            PosterRow(items: vm.newlyVideos)
                        }

                        if !vm.moviesPage1.isEmpty {
                            SectionTitle("Movies")
                            PosterRow(items: vm.moviesPage1)
                        }

                        if !vm.seriesPage1.isEmpty {
                            SectionTitle("Series")
                            PosterRow(items: vm.seriesPage1)
                        }

                        if !vm.moviesPage2.isEmpty {
                            SectionTitle("More Movies")
                            PosterRow(items: vm.moviesPage2)
                        }

                        ForEach(vm.groups) { grp in
                            if let items = vm.groupVideos[grp.id], !items.isEmpty {
                                SectionTitle(grp.displayTitle)
                                PosterRow(items: items)
                            }
                        }

                        if vm.banners.isEmpty && vm.moviesPage1.isEmpty && !vm.isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 50)).foregroundColor(.secondary)
                                Text("Could not load content").foregroundColor(.secondary)
                                Button("Retry") { vm.loadHome() }
                                    .buttonStyle(.borderedProminent).tint(.red)
                            }.frame(maxWidth: .infinity).padding(60)
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

// MARK: - Section Title
struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.title2).bold().padding(.horizontal)
    }
}

// MARK: - Banner Carousel
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

// MARK: - Poster Row
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

// MARK: - Banner Card
struct BannerCard: View {
    let item: VideoItem
    var body: some View {
        ZStack(alignment: .bottom) {
            CachedImage(url: item.fullURL ?? item.medURL, width: 260, height: 150)
            LinearGradient(colors: [.clear, .black.opacity(0.85)],
                           startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.caption).bold().foregroundColor(.white).lineLimit(1)
                if let score = item.imdbScore {
                    IMDbBadge(score: score)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 260, height: 150)
        .cornerRadius(12).shadow(radius: 4)
    }
}

// MARK: - Poster Card
struct PosterCard: View {
    let item: VideoItem
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .topTrailing) {
                CachedImage(url: item.thumbURL ?? item.medURL, width: 110, height: 160)
                    .cornerRadius(8)
                if let score = item.imdbScore {
                    HStack(spacing: 2) {
                        Text("IMDb").font(.system(size: 7, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 3).padding(.vertical, 1)
                            .background(Color.yellow).cornerRadius(2)
                        Text(score).font(.system(size: 9, weight: .bold)).foregroundColor(.yellow)
                    }
                    .padding(4)
                }
            }
            Text(item.displayTitle)
                .font(.caption).bold().lineLimit(2)
                .frame(width: 110, alignment: .leading)
            if let yr = item.year {
                Text(yr).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Cached Image
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
