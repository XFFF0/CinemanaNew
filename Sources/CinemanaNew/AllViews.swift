import SwiftUI

// MARK: ==================== SEARCH ====================
@MainActor
class SearchVM: ObservableObject {
    @Published var query = ""
    @Published var type = "all"
    @Published var results: [Video] = []
    @Published var categories: [CategoryItem] = []
    @Published var isLoading = false
    private let api = APIService.shared
    private var task: Task<Void, Never>?

    func onQueryChange() {
        task?.cancel()
        guard query.count >= 2 else { if query.isEmpty { results = [] }; return }
        task = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    func search() async {
        isLoading = true
        results = (try? await api.search(query: query, type: type)) ?? []
        isLoading = false
    }

    func loadCategories() async {
        categories = (try? await api.fetchCategories()) ?? []
    }
}

struct SearchView: View {
    @StateObject private var vm = SearchVM()
    @FocusState private var focused: Bool
    private let types = [("all","All"),("movie","Movies"),("series","Series")]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.textSec)
                            TextField("Search movies & series...", text: $vm.query)
                                .foregroundColor(.white).focused($focused)
                                .submitLabel(.search).onSubmit { Task { await vm.search() } }
                                .onChange(of: vm.query) { _, _ in vm.onQueryChange() }
                            if !vm.query.isEmpty {
                                Button { vm.query = ""; vm.results = [] } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.textSec)
                                }
                            }
                        }
                        .padding(12).background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(16)

                    // Type filter
                    HStack(spacing: 8) {
                        ForEach(types, id: \.0) { t in
                            Button {
                                vm.type = t.0
                                if !vm.query.isEmpty { Task { await vm.search() } }
                            } label: {
                                Text(t.1).font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(vm.type == t.0 ? .white : .textSec)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(vm.type == t.0 ? Color.cRed : Color.cardBg)
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)

                    if vm.isLoading {
                        Spacer()
                        ProgressView().tint(.cRed)
                        Spacer()
                    } else if vm.results.isEmpty && !vm.query.isEmpty {
                        EmptyState(icon: "film.slash", title: "No Results",
                                   subtitle: "Try different search terms")
                    } else if vm.results.isEmpty {
                        CatsGrid(categories: vm.categories)
                    } else {
                        ResultsGrid(results: vm.results)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .task { await vm.loadCategories() }
        }
    }
}

struct ResultsGrid: View {
    let results: [Video]
    private let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(results) { v in
                    NavigationLink(destination: DetailView(videoId: v.id)) {
                        VideoCard(video: v, width: 110, height: 165)
                    }.buttonStyle(.plain)
                }
            }
            .padding(16).padding(.bottom, 100)
        }
    }
}

struct CatsGrid: View {
    let categories: [CategoryItem]
    private let cols = [GridItem(.flexible()), GridItem(.flexible())]
    private let colors: [Color] = [.cRed, .blue, .purple, .green, .orange, .teal, .pink, .indigo]
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { i, cat in
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(
                                colors: [colors[i % colors.count], colors[i % colors.count].opacity(0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text(cat.displayName).font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).multilineTextAlignment(.center).padding(12)
                    }.frame(height: 80)
                }
            }
            .padding(16).padding(.bottom, 100)
        }
    }
}

// MARK: ==================== DOWNLOADS ====================
struct DownloadsView: View {
    @EnvironmentObject var dl: DownloadManager
    @State private var seg = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $seg) {
                        Text("Active (\(dl.active.count))").tag(0)
                        Text("Completed (\(dl.completed.count))").tag(1)
                    }
                    .pickerStyle(.segmented).padding(16)

                    if seg == 0 {
                        if dl.active.isEmpty {
                            EmptyState(icon: "arrow.down.circle",
                                       title: "No Active Downloads",
                                       subtitle: "Start downloading from any video")
                        } else {
                            List {
                                ForEach(dl.active) { item in
                                    ActiveDlRow(item: item)
                                        .listRowBackground(Color.cardBg)
                                        .listRowSeparatorTint(Color.separator)
                                }
                            }
                            .listStyle(.plain).scrollContentBackground(.hidden)
                        }
                    } else {
                        if dl.completed.isEmpty {
                            EmptyState(icon: "checkmark.circle",
                                       title: "No Completed Downloads",
                                       subtitle: "Finished downloads appear here")
                        } else {
                            List {
                                ForEach(dl.completed) { item in
                                    CompletedDlRow(item: item)
                                        .listRowBackground(Color.cardBg)
                                        .listRowSeparatorTint(Color.separator)
                                }
                                .onDelete { idx in
                                    let items = dl.completed
                                    for i in idx { dl.cancel(items[i].id) }
                                }
                            }
                            .listStyle(.plain).scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ActiveDlRow: View {
    let item: DownloadItem
    @EnvironmentObject var dl: DownloadManager

    var body: some View {
        HStack(spacing: 14) {
            CImg(url: item.posterImage, mode: .fill, radius: 10).frame(width: 80, height: 55)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPri).lineLimit(2)
                HStack(spacing: 8) {
                    Text(item.quality).font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gold).clipShape(Capsule())
                    Text(item.progressText).font(.system(size: 11)).foregroundColor(.textSec)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.surface).frame(height: 4)
                        Capsule().fill(item.status.color)
                            .frame(width: g.size.width * item.progress, height: 4)
                    }
                }.frame(height: 4)
                HStack(spacing: 4) {
                    Image(systemName: item.status.icon).font(.system(size: 11))
                    Text(item.status.rawValue.capitalized).font(.system(size: 11))
                }.foregroundColor(item.status.color)
            }

            Spacer()

            VStack(spacing: 10) {
                switch item.status {
                case .downloading:
                    Button { dl.pause(item.id) } label: {
                        Image(systemName: "pause.circle.fill").font(.system(size: 26)).foregroundColor(.orange)
                    }
                case .paused, .failed:
                    Button { dl.resume(item.id) } label: {
                        Image(systemName: "play.circle.fill").font(.system(size: 26)).foregroundColor(.blue)
                    }
                default: EmptyView()
                }
                Button { dl.cancel(item.id) } label: {
                    Image(systemName: "xmark.circle").font(.system(size: 22)).foregroundColor(.textMuted)
                }
            }
        }.padding(.vertical, 8)
    }
}

struct CompletedDlRow: View {
    let item: DownloadItem
    @EnvironmentObject var dl: DownloadManager
    @State private var showPlayer = false

    var body: some View {
        HStack(spacing: 14) {
            CImg(url: item.posterImage, mode: .fill, radius: 10).frame(width: 80, height: 55)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPri).lineLimit(2)
                HStack(spacing: 8) {
                    Text(item.quality).font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gold).clipShape(Capsule())
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11)).foregroundColor(.green)
                }
            }
            Spacer()
            Button {
                if dl.localURL(item.id) != nil { showPlayer = true }
            } label: {
                Image(systemName: "play.circle.fill").font(.system(size: 32)).foregroundColor(.cRed)
            }
        }
        .padding(.vertical, 8)
        .fullScreenCover(isPresented: $showPlayer) {
            if let url = dl.localURL(item.id) {
                PlayerView(streams: [StreamFile(url: url.absoluteString)],
                           subs: [], title: item.title)
            }
        }
    }
}

// MARK: ==================== WATCH LATER ====================
struct WatchLaterView: View {
    @EnvironmentObject var wl: WatchLaterManager
    private let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                if wl.items.isEmpty {
                    EmptyState(icon: "bookmark.slash", title: "Nothing Saved",
                               subtitle: "Tap the bookmark icon on any video")
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: cols, spacing: 14) {
                            ForEach(wl.items) { item in
                                NavigationLink(destination: DetailView(videoId: item.videoId)) {
                                    WLCard(item: item)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation { wl.remove(item.videoId) }
                                    } label: { Label("Remove", systemImage: "trash") }
                                }
                            }
                        }
                        .padding(16).padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Watch Later")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct WLCard: View {
    let item: WatchLaterItem
    @EnvironmentObject var wl: WatchLaterManager
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                CImg(url: item.poster, mode: .fill, radius: 12).frame(width: 110, height: 165)
                Button {
                    withAnimation { wl.remove(item.videoId) }
                } label: {
                    Image(systemName: "bookmark.fill").font(.system(size: 14)).foregroundColor(.cRed)
                        .padding(6).background(Color.black.opacity(0.6)).clipShape(Circle())
                }.padding(6)
            }
            Text(item.title).font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textPri).lineLimit(2).frame(width: 110, alignment: .leading)
            if let y = item.year {
                Text(y).font(.system(size: 11)).foregroundColor(.textSec)
            }
        }
    }
}

// MARK: ==================== PROFILE ====================
struct ProfileView: View {
    @EnvironmentObject var api: APIService
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                if api.isLoggedIn { LoggedInView() } else { GuestView() }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct LoggedInView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var dl: DownloadManager
    @EnvironmentObject var wl: WatchLaterManager

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.cRed).frame(width: 70, height: 70)
                        Image(systemName: "person.fill").font(.system(size: 30)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(api.userInfo?.name ?? "User")
                            .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        Text(api.userInfo?.email ?? "")
                            .font(.system(size: 14)).foregroundColor(.textSec)
                    }
                }.padding(.vertical, 8)
            }.listRowBackground(Color.cardBg)

            Section("Library") {
                StatRow(icon: "arrow.down.circle.fill", label: "Downloads", value: "\(dl.downloads.count)", color: .blue)
                StatRow(icon: "bookmark.fill", label: "Watch Later", value: "\(wl.items.count)", color: .cRed)
            }.listRowBackground(Color.cardBg)

            Section {
                Button(role: .destructive) { api.logout() } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }.foregroundColor(.cRed)
                }
            }.listRowBackground(Color.cardBg)
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden)
    }
}

struct GuestView: View {
    @State private var showLogin = false
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Color.cardBg).frame(width: 100, height: 100)
                Image(systemName: "person.circle").font(.system(size: 50)).foregroundColor(.textSec)
            }
            VStack(spacing: 8) {
                Text("Sign In for Full Access")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                Text("Watch, download, and save your favourites\nwith your Shabakaty account")
                    .font(.system(size: 15)).foregroundColor(.textSec).multilineTextAlignment(.center)
            }
            Button { showLogin = true } label: {
                Text("Sign In").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                    .frame(width: 200).padding(.vertical, 14)
                    .background(Color.cRed).clipShape(Capsule())
            }
            Spacer()
        }
        .sheet(isPresented: $showLogin) { LoginView() }
    }
}

struct StatRow: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 28)
            Text(label).foregroundColor(.textPri)
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundColor(.textSec)
        }
    }
}

// MARK: ==================== LOGIN ====================
struct LoginView: View {
    @EnvironmentObject var api: APIService
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showPass = false
    @State private var isRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer()
                    // Logo
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.cRed).frame(width: 80, height: 80)
                                .shadow(color: Color.cRed.opacity(0.5), radius: 20)
                            Image(systemName: "film.fill").font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                        }
                        Text("Cinemana New").font(.system(size: 28, weight: .black)).foregroundColor(.white)
                        Text(isRegister ? "Create Account" : "Sign In")
                            .font(.system(size: 15)).foregroundColor(.textSec)
                    }

                    // Form
                    VStack(spacing: 14) {
                        Field(icon: "envelope", placeholder: "Email", text: $email,
                              keyboard: .emailAddress, autocap: .none)

                        PasswordField(placeholder: "Password", text: $password, show: $showPass)

                        if let err = error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.cRed)
                                Text(err).font(.system(size: 13)).foregroundColor(.cRed)
                            }
                            .padding(12).background(Color.cRed.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            HStack {
                                if isLoading { ProgressView().tint(.white) }
                                else { Text(isRegister ? "Create Account" : "Sign In")
                                    .font(.system(size: 17, weight: .bold)) }
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(colors: [Color.cRedLight, Color.cRed],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.cRed.opacity(0.4), radius: 12, y: 6)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)

                        Button {
                            withAnimation { isRegister.toggle(); error = nil }
                        } label: {
                            Text(isRegister ? "Already have an account? Sign In" : "New? Create an Account")
                                .font(.system(size: 14)).foregroundColor(.cRed)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                    Text("Powered by Shabakaty").font(.system(size: 12)).foregroundColor(.textMuted).padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSec)
                }
            }
        }
    }

    private func submit() async {
        isLoading = true; error = nil
        do {
            try await api.login(email: email, password: password)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct Field: View {
    let icon: String; let placeholder: String; @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .sentences
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.textSec).frame(width: 24)
            TextField(placeholder, text: $text)
                .foregroundColor(.white).keyboardType(keyboard)
                .textInputAutocapitalization(autocap).autocorrectionDisabled()
        }
        .padding(16).background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

struct PasswordField: View {
    let placeholder: String; @Binding var text: String; @Binding var show: Bool
    var body: some View {
        HStack {
            Image(systemName: "lock").foregroundColor(.textSec).frame(width: 24)
            Group {
                if show { TextField(placeholder, text: $text) }
                else { SecureField(placeholder, text: $text) }
            }.foregroundColor(.white)
            Button { show.toggle() } label: {
                Image(systemName: show ? "eye.slash" : "eye").foregroundColor(.textSec)
            }
        }
        .padding(16).background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - StreamFile init from URL (for local playback)
extension StreamFile {
    init(url: String) {
        self.url = url
        self.quality = "Local"
        self.resolution = nil
        self.fileSize = nil
    }
}
