import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.3))

                        Text("Connection Error")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)

                        Button(action: {
                            Task { await viewModel.refresh() }
                        }) {
                            Text("Retry")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.primaryAccent)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            if !viewModel.banners.isEmpty {
                                FeaturedSection(banners: viewModel.banners)
                            }

                            if !viewModel.newlyVideos.isEmpty {
                                VideoSection(title: "New Releases", videos: viewModel.newlyVideos)
                            }

                            ForEach(viewModel.homeGroups) { group in
                                if let videos = group.videos, !videos.isEmpty {
                                    VideoSection(
                                        title: group.displayName,
                                        videos: videos
                                    )
                                }
                            }

                            if !viewModel.collections.isEmpty {
                                CollectionsSection(collections: viewModel.collections)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, 10)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Cinemana")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
    }
}

struct FeaturedSection: View {
    let banners: [VideoModel]
    @State private var currentIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TabView(selection: $currentIndex) {
                ForEach(Array(banners.enumerated()), id: \.element.nb) { index, video in
                    NavigationLink(destination: VideoDetailView(video: video)) {
                        FeaturedCard(video: video) {}
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 260)
            .padding(.horizontal, 16)
        }
    }
}

struct VideoSection: View {
    let title: String
    let videos: [VideoModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(videos) { video in
                        NavigationLink(destination: VideoDetailView(video: video)) {
                            VideoCard(video: video)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct CollectionsSection: View {
    let collections: [CollectionItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collections")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(collections) { collection in
                        NavigationLink(destination: CollectionDetailView(collection: collection)) {
                            CollectionCard(collection: collection)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct CollectionCard: View {
    let collection: CollectionItem

    var body: some View {
        VStack(alignment: .leading) {
            KFImage(URL(string: collection.imageUrl ?? ""))
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 280, height: 160)
                .cornerRadius(12)
                .clipped()

            Text(collection.displayName)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

struct CollectionDetailView: View {
    let collection: CollectionItem
    @State private var videos: [VideoModel] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(videos) { video in
                            NavigationLink(destination: VideoDetailView(video: video)) {
                                LargeVideoCard(video: video)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(collection.displayName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            do {
                videos = try await APIService.shared.getCollectionDetails(collectionId: collection.nb ?? "")
            } catch {
                print("Error loading collection: \(error)")
            }
            isLoading = false
        }
    }
}

import Kingfisher

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}