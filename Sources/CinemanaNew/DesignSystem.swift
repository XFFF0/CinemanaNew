import SwiftUI

// MARK: - Colors
extension Color {
    static let appBg      = Color(hex: "#06111C")
    static let cardBg     = Color(hex: "#0D1F2D")
    static let surface    = Color(hex: "#112233")
    static let cRed       = Color(hex: "#C82127")
    static let cRedLight  = Color(hex: "#E8353C")
    static let gold       = Color(hex: "#F5C842")
    static let textPri    = Color.white
    static let textSec    = Color(hex: "#8FA8BF")
    static let textMuted  = Color(hex: "#4A6275")
    static let separator  = Color(hex: "#1A3045")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: h).scanHexInt64(&n)
        let a, r, g, b: UInt64
        switch h.count {
        case 6: (a,r,g,b) = (255, n>>16, n>>8 & 0xFF, n & 0xFF)
        case 8: (a,r,g,b) = (n>>24, n>>16 & 0xFF, n>>8 & 0xFF, n & 0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Liquid Glass
struct LiquidGlass: ViewModifier {
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content.background(
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.04), Color.cRed.opacity(0.06)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05),
                                                          Color.cRed.opacity(0.15), .white.opacity(0.08)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
            }
        )
    }
}

extension View {
    func liquidGlass(_ radius: CGFloat = 20) -> some View { modifier(LiquidGlass(radius: radius)) }
}

// MARK: - Async Image
struct CImg: View {
    let url: URL?
    var mode: ContentMode = .fill
    var radius: CGFloat = 0
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.surface)
                    .overlay(ProgressView().tint(Color.cRed))
            case .success(let img):
                img.resizable().aspectRatio(contentMode: mode)
            default:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.surface)
                    .overlay(Image(systemName: "photo").foregroundColor(Color.textMuted))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - Section Header
struct SectionHead: View {
    let title: String
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(.textPri)
            Spacer()
            if let a = action {
                Button("See All", action: a).font(.system(size: 14, weight: .semibold)).foregroundColor(.cRed)
            }
        }.padding(.horizontal, 16)
    }
}

// MARK: - Rating Badge
struct RatingBadge: View {
    let rating: Double
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.gold)
            Text(String(format: "%.1f", rating)).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.black.opacity(0.6)).clipShape(Capsule())
    }
}

// MARK: - Video Card
struct VideoCard: View {
    let video: Video
    var width: CGFloat = 140
    var height: CGFloat = 210
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                CImg(url: video.posterURL, mode: .fill, radius: 12)
                    .frame(width: width, height: height).clipped()
                VStack(alignment: .leading, spacing: 4) {
                    if video.hdFlag {
                        Text("HD").font(.system(size: 10, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.gold).clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if video.isSeries {
                        Text("Series").font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.cRed.opacity(0.85)).clipShape(Capsule())
                    }
                }.padding(6)
                if let r = video.rating {
                    VStack { Spacer(); HStack { Spacer(); RatingBadge(rating: r) } }.padding(6)
                }
            }
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

            Text(video.displayTitle).font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPri).lineLimit(2).frame(width: width, alignment: .leading)
            if let y = video.year { Text(y).font(.system(size: 11)).foregroundColor(.textSec) }
        }
    }
}

// MARK: - Loading
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.appBg.opacity(0.85)
            VStack(spacing: 16) {
                ProgressView().progressViewStyle(.circular).tint(Color.cRed).scaleEffect(1.4)
                Text("Loading...").font(.system(size: 14)).foregroundColor(.textSec)
            }
        }
    }
}

// MARK: - Empty State
struct EmptyState: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon).font(.system(size: 56)).foregroundColor(.textMuted)
            Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(.textPri)
            Text(subtitle).font(.system(size: 14)).foregroundColor(.textSec)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Cinemana Logo in NavBar
struct CinLogo: View {
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(Color.cRed).frame(width: 28, height: 28)
                Image(systemName: "film.fill").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            }
            (Text("Cinemana").font(.system(size: 20, weight: .black)).foregroundColor(.white)
             + Text(" New").font(.system(size: 20, weight: .thin)).foregroundColor(.cRed))
        }
    }
}

// MARK: - Tab Bar
struct AppTabBar: View {
    @Binding var selected: AppTab
    @EnvironmentObject var downloads: DownloadManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = tab }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(selected == tab ? Color.cRed : Color.textSec)
                            if tab == .downloads {
                                let n = downloads.active.count
                                if n > 0 {
                                    Text("\(n)").font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white).padding(4)
                                        .background(Color.cRed).clipShape(Circle())
                                        .offset(x: 10, y: -10)
                                }
                            }
                        }
                        Text(tab.label).font(.system(size: 10, weight: selected == tab ? .semibold : .regular))
                            .foregroundStyle(selected == tab ? Color.cRed : Color.textMuted)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8).padding(.bottom, 8)
        .liquidGlass(28)
        .shadow(color: .black.opacity(0.4), radius: 20, y: -4)
        .padding(.horizontal, 16).padding(.bottom, 8)
    }
}

enum AppTab: CaseIterable {
    case home, search, downloads, watchLater, profile
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .downloads: return "arrow.down.circle.fill"
        case .watchLater: return "bookmark.fill"
        case .profile: return "person.circle.fill"
        }
    }
    var label: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .downloads: return "Downloads"
        case .watchLater: return "Saved"
        case .profile: return "Profile"
        }
    }
}
