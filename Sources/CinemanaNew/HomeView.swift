import SwiftUI

@MainActor
class HomeVM: ObservableObject {
    @Published var banners: [Banner] = []
    @Published var groups: [VideoGroup] = []
    @Published var newly: [Video] = []
    @Published var isLoading = false
    @Published var bannerIdx = 0
    private let api = APIService.shared

    func load() async {
        isLoading = true
        async let b = (try? api.fetchBanners()) ?? []
        async let g = (try? api.fetchVideoGroups()) ?? []
        async let n = (try? api.fetchNewlyVideos()) ?? []
        let (bv, gv, nv) = await (b, g, n)
        banners = bv; groups = gv; newly = nv
        isLoading = false
    }
}

struct HomeView: View {
    @StateObject private var vm = HomeVM()
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 28) {
                        if !vm.banners.isEmpty {
                            BannerCarousel(banners: vm.banners, idx: $vm.bannerIdx)
                                .frame(height: 460)
                        }
                        if !vm.newly.isEmpty {
                            VStack(spacing: 12) {
                                SectionHead(title: "New Arrivals")
                                HScroll(vm.newly)
                            }
                        }
                        ForEach(vm.groups) { g in
                            if let vids = g.videos, !vids.isEmpty {
                                VStack(spacing: 12) {
                                    SectionHead(title: g.displayTitle)
                                    HScroll(vids)
                                }
                            }
                        }
                        Spacer(minLength: 100)
                    }
                }
                .refreshable { await vm.load() }
                if vm.isLoading && vm.banners.isEmpty { LoadingView() }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { CinLogo() }
            }
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    func HScroll(_ videos: [Video]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(videos) { v in
                    NavigationLink(destination: DetailView(videoId: v.id)) {
                        VideoCard(video: v)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 16)
        }
    }
}

// MARK: - Banner Carousel
struct BannerCarousel: View {
    let banners: [Banner]
    @Binding var idx: Int
    @State private var timer: Timer?

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $idx) {
                ForEach(Array(banners.enumerated()), id: \.offset) { i, b in
                    BannerSlide(banner: b).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            LinearGradient(colors: [.clear, Color.appBg.opacity(0.5), Color.appBg],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 200)

            HStack(spacing: 6) {
                ForEach(0..<banners.count, id: \.self) { i in
                    Capsule()
                        .fill(i == idx ? Color.cRed : Color.white.opacity(0.3))
                        .frame(width: i == idx ? 24 : 6, height: 6)
                        .animation(.spring(response: 0.3), value: idx)
                }
            }.padding(.bottom, 20)
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    idx = (idx + 1) % banners.count
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}

struct BannerSlide: View {
    let banner: Banner
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CImg(url: banner.imageURL, mode: .fill).clipped()
            LinearGradient(colors: [.clear, Color.appBg.opacity(0.8)], startPoint: .center, endPoint: .bottom)
            if let t = banner.title {
                VStack(alignment: .leading, spacing: 12) {
                    Text(t).font(.system(size: 26, weight: .black)).foregroundColor(.white)
                        .shadow(radius: 4).lineLimit(2)
                    if let vid = banner.videoId {
                        NavigationLink(destination: DetailView(videoId: vid)) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text("Watch Now").fontWeight(.bold)
                            }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 12)
                            .background(Color.cRed).clipShape(Capsule())
                        }
                    }
                }.padding(20)
            }
        }.clipped()
    }
}
