import SwiftUI
import Kingfisher

struct VideoCard: View {
    let video: VideoModel
    var showProgress: Bool = false
    var progress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                KFImage(URL(string: video.thumbnailUrl ?? ""))
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(width: 120, height: 180)
                    .cornerRadius(10)
                    .clipped()

                if video.isSeries {
                    if let season = video.season {
                        Text("S\(season)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primaryAccent)
                            .cornerRadius(4)
                            .padding(4)
                    }
                }

                if showProgress && progress > 0 {
                    VStack {
                        Spacer()
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.primaryAccent)
                                .frame(width: geometry.size.width * progress, height: 3)
                        }
                        .frame(height: 3)
                    }
                }
            }

            Text(video.title)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            if !video.rating.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)

                    Text(video.rating)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

struct LargeVideoCard: View {
    let video: VideoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KFImage(URL(string: video.posterUrl ?? ""))
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(height: 180)
                .cornerRadius(12)
                .clipped()

            Text(video.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)

            HStack(spacing: 8) {
                if let year = video.year {
                    Text(year)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                if let duration = video.duration, !duration.isEmpty {
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))

                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                if !video.rating.isEmpty {
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)

                        Text(video.rating)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }
}

struct FeaturedCard: View {
    let video: VideoModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                KFImage(URL(string: video.posterUrl ?? ""))
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(height: 250)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 120)

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if let year = video.year {
                            Text(year)
                        }

                        if !video.rating.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)

                                Text(video.rating)
                            }
                        }

                        if let duration = video.duration, !duration.isEmpty {
                            Text(duration)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            }
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct CategoryPill: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isPrimaryAccent ? Color.primaryAccent : Color.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.primaryAccent : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)

    }

    private var isPrimaryAccent: Bool {
        isSelected
    }
}

struct LoadingShimmer: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QualitySelector: View {
    @Binding var selectedQuality: String
    let availableQualities: [TranscodeFile]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(availableQualities.sorted(by: { ($0.resolution ?? "") > ($1.resolution ?? "") }), id: \.id) { file in
                    Button(action: {
                        selectedQuality = file.resolution ?? ""
                    }) {
                        Text(file.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedQuality == file.resolution ? .white : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedQuality == file.resolution ? Color.primaryAccent : Color.cardBackground)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SubtitleSettingsView: View {
    @Binding var enabled: Bool
    @Binding var position: SubtitlePosition
    @Binding var size: SubtitleSize
    let availableLanguages: [TranslationInfo]
    @Binding var selectedLanguage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle(isOn: $enabled) {
                Text("Subtitles")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .tint(.primaryAccent)

            if enabled {
                if !availableLanguages.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Language")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableLanguages, id: \.language) { lang in
                                    Button(action: {
                                        selectedLanguage = lang.language
                                    }) {
                                        Text(lang.languageName ?? lang.language ?? "Unknown")
                                            .font(.caption)
                                            .foregroundColor(selectedLanguage == lang.language ? .white : .white.opacity(0.7))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedLanguage == lang.language ? Color.primaryAccent : Color.cardBackground)
                                            .cornerRadius(16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Position")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 8) {
                        ForEach(SubtitlePosition.allCases, id: \.self) { pos in
                            Button(action: {
                                position = pos
                            }) {
                                Text(pos.displayName)
                                    .font(.caption)
                                    .foregroundColor(position == pos ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(position == pos ? Color.primaryAccent : Color.cardBackground)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Size")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 8) {
                        ForEach(SubtitleSize.allCases, id: \.self) { s in
                            Button(action: {
                                size = s
                            }) {
                                Text(s.displayName)
                                    .font(.caption)
                                    .foregroundColor(size == s ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(size == s ? Color.primaryAccent : Color.cardBackground)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}