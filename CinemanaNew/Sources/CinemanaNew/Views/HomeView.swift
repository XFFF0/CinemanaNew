import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                if vm.isLoading {
                    ProgressView()
                        .padding(60)
                } else {
                    VStack(alignment: .leading, spacing: 24) {

                        // Banner carousel
                        if !vm.banners.isEmpty {
                            SectionHeader(title: "Featured")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.banners.prefix(10)) { item in
                                        NavigationLink(destination: DetailView(video: item)) {
                                            BannerCard(item: item)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // New releases
                        if !vm.newlyVideos.isEmpty {
                            SectionHeader(title: "New Releases")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.newlyVideos.prefix(20)) { item in
                                        NavigationLink(destination: DetailView(video: item)) {
                                            PosterCard(item: item)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Cinemana New")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { vm.loadHome() }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2).bold()
            .padding(.horizontal)
    }
}

struct BannerCard: View {
    let item: VideoItem
    var body: some View {
        AsyncImage(url: URL(string: item.imgMediumThumbObjUrl ?? item.imgObjUrl ?? "")) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            default:
                Color.gray.opacity(0.3)
                    .overlay(Image(systemName: "film").font(.largeTitle).foregroundColor(.white))
            }
        }
        .frame(width: 260, height: 150)
        .clipped()
        .cornerRadius(12)
        .overlay(
            VStack {
                Spacer()
                Text(item.displayTitle)
                    .font(.caption).bold()
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.6))
            }
        )
        .cornerRadius(12)
    }
}

struct PosterCard: View {
    let item: VideoItem
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: URL(string: item.imgThumbObjUrl ?? item.imgObjUrl ?? "")) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Color.gray.opacity(0.3)
                        .overlay(Image(systemName: "film").foregroundColor(.white))
                }
            }
            .frame(width: 110, height: 160)
            .clipped()
            .cornerRadius(8)

            Text(item.displayTitle)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)

            if let year = item.year {
                Text(year)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
