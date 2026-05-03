import SwiftUI
import AVKit
import AVFoundation
import Combine

@MainActor
class PlayerVM: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading = true
    @Published var showControls = true
    @Published var selectedStream: StreamFile?
    @Published var selectedSub: SubtitleFile?
    @Published var subText = ""
    @Published var subSettings = SubtitleSettings()
    @Published var showSubSettings = false
    @Published var showQuality = false

    let streams: [StreamFile]
    let subs: [SubtitleFile]
    let title: String

    private var timeObs: Any?
    private var ctrlTimer: Timer?
    private var subCues: [(s: Double, e: Double, t: String)] = []
    private var cancellables = Set<AnyCancellable>()

    init(streams: [StreamFile], subs: [SubtitleFile], title: String) {
        self.streams = streams; self.subs = subs; self.title = title
        if let d = UserDefaults.standard.data(forKey: "sub_settings"),
           let s = try? JSONDecoder().decode(SubtitleSettings.self, from: d) { subSettings = s }
    }

    func setup() {
        let file = streams.first(where: { $0.qualityOrder == streams.map(\.qualityOrder).max() }) ?? streams.first
        guard let f = file else { return }
        selectedStream = f
        loadURL(f.url)
        if let sub = subs.first { loadSub(sub) }
    }

    func loadURL(_ urlStr: String) {
        guard let url = URL(string: urlStr) else { return }
        isLoading = true
        player?.pause()
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        timeObs = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] t in
            self?.currentTime = t.seconds
            self?.updateSub()
        }
        p.publisher(for: \.status).receive(on: DispatchQueue.main).sink { [weak self] s in
            if s == .readyToPlay {
                self?.isLoading = false
                self?.duration = p.currentItem?.duration.seconds ?? 0
                p.play(); self?.isPlaying = true
            }
        }.store(in: &cancellables)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.isPlaying = false
        }
        player = p
    }

    func switchQuality(_ s: StreamFile) {
        let t = currentTime; selectedStream = s
        loadURL(s.url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.player?.seek(to: CMTime(seconds: t, preferredTimescale: 600))
        }
    }

    func togglePlay() { isPlaying ? player?.pause() : player?.play(); isPlaying.toggle() }
    func skip(_ s: Double) { player?.seek(to: CMTime(seconds: max(0, min(currentTime + s, duration)), preferredTimescale: 600)) }

    func showCtrl() {
        withAnimation { showControls = true }
        ctrlTimer?.invalidate()
        ctrlTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            withAnimation { self?.showControls = false }
        }
    }

    func saveSubSettings() {
        if let d = try? JSONEncoder().encode(subSettings) { UserDefaults.standard.set(d, forKey: "sub_settings") }
    }

    func loadSub(_ f: SubtitleFile) {
        selectedSub = f
        guard let url = f.subURL else { return }
        Task {
            guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { return }
            let cues = parseSRT(text)
            await MainActor.run { subCues = cues }
        }
    }

    private func parseSRT(_ t: String) -> [(s: Double, e: Double, t: String)] {
        var out: [(Double, Double, String)] = []
        for block in t.components(separatedBy: "\n\n") {
            let lines = block.components(separatedBy: "\n")
            guard lines.count >= 3 else { continue }
            let parts = lines[1].components(separatedBy: " --> ")
            guard parts.count == 2 else { continue }
            out.append((parseTime(parts[0]), parseTime(parts[1]),
                        lines[2...].joined(separator: "\n").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)))
        }
        return out
    }

    private func parseTime(_ s: String) -> Double {
        let clean = s.trimmingCharacters(in: .whitespaces)
        let parts = clean.components(separatedBy: ":")
        if parts.count == 3 {
            return (Double(parts[0]) ?? 0) * 3600 + (Double(parts[1]) ?? 0) * 60
                + (Double(parts[2].replacingOccurrences(of: ",", with: ".")) ?? 0)
        }
        return 0
    }

    private func updateSub() {
        let t = subCues.first { $0.s <= currentTime && $0.e >= currentTime }?.t ?? ""
        if t != subText { subText = t }
    }

    var timeStr: String { fmt(currentTime) }
    var durStr: String { fmt(duration) }
    private func fmt(_ s: Double) -> String {
        guard !s.isNaN && !s.isInfinite else { return "0:00" }
        let t = Int(s); let h = t/3600; let m = (t%3600)/60; let sec = t%60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }
}

// MARK: - Player View
struct PlayerView: View {
    let streams: [StreamFile]; let subs: [SubtitleFile]; let title: String
    @StateObject private var vm: PlayerVM
    @Environment(\.dismiss) var dismiss

    init(streams: [StreamFile], subs: [SubtitleFile], title: String) {
        self.streams = streams; self.subs = subs; self.title = title
        _vm = StateObject(wrappedValue: PlayerVM(streams: streams, subs: subs, title: title))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let p = vm.player { AVLayerView(player: p).ignoresSafeArea() }
            if vm.isLoading { ProgressView().tint(.white).scaleEffect(1.5) }
            SubOverlay(vm: vm)
            if vm.showControls { ControlsOverlay(vm: vm, dismiss: { dismiss() }) }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { vm.showControls.toggle() }; if vm.showControls { vm.showCtrl() } }
        .onAppear { vm.setup() }
        .onDisappear { vm.player?.pause() }
        .sheet(isPresented: $vm.showSubSettings) {
            SubSettingsSheet(vm: vm).presentationDetents([.fraction(0.75)])
        }
        .sheet(isPresented: $vm.showQuality) {
            QualitySheet(streams: vm.streams) { s in vm.switchQuality(s); vm.showQuality = false }
                .presentationDetents([.fraction(0.4)])
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - AVPlayer UIKit wrapper
struct AVLayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> AVView { let v = AVView(); v.player = player; return v }
    func updateUIView(_ v: AVView, context: Context) { v.player = player }
}
class AVView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var player: AVPlayer? {
        get { (layer as? AVPlayerLayer)?.player }
        set { (layer as? AVPlayerLayer)?.player = newValue }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        (layer as? AVPlayerLayer)?.videoGravity = .resizeAspect
        backgroundColor = .black
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Subtitle Overlay
struct SubOverlay: View {
    @ObservedObject var vm: PlayerVM
    var body: some View {
        if vm.subSettings.isEnabled && !vm.subText.isEmpty {
            let s = vm.subSettings
            GeometryReader { _ in
                VStack {
                    if s.position == .top { subLabel(s) }
                    Spacer()
                    if s.position == .center { subLabel(s) }
                    Spacer()
                    if s.position == .bottom { subLabel(s) }
                }
                .padding(.bottom, s.position == .bottom ? s.offsetY : 0)
                .padding(.top, s.position == .top ? s.offsetY : 0)
                .padding(.horizontal, 20)
            }
        }
    }
    @ViewBuilder func subLabel(_ s: SubtitleSettings) -> some View {
        Text(vm.subText)
            .font(.custom(s.fontName, size: s.fontSize))
            .foregroundColor(Color(hex: s.textColor))
            .multilineTextAlignment(.center)
            .shadow(color: .black, radius: 2, x: 1, y: 1)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(hex: "#000000").opacity(s.bgOpacity).clipShape(RoundedRectangle(cornerRadius: 6)))
    }
}

// MARK: - Controls Overlay
struct ControlsOverlay: View {
    @ObservedObject var vm: PlayerVM
    let dismiss: () -> Void
    var body: some View {
        ZStack {
            VStack {
                LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 160)
            }
            VStack {
                // Top
                HStack {
                    Button(action: dismiss) {
                        Image(systemName: "chevron.down.circle.fill").font(.system(size: 28)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(vm.title).font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    HStack(spacing: 16) {
                        Button { vm.showSubSettings = true } label: {
                            Image(systemName: vm.subSettings.isEnabled ? "captions.bubble.fill" : "captions.bubble")
                                .font(.system(size: 22)).foregroundColor(.white)
                        }
                        Button { vm.showQuality = true } label: {
                            Image(systemName: "slider.horizontal.3").font(.system(size: 22)).foregroundColor(.white)
                        }
                    }
                }.padding(.horizontal, 20).padding(.top, 50)
                Spacer()
                // Center
                HStack(spacing: 50) {
                    Button { vm.skip(-10) } label: {
                        Image(systemName: "gobackward.10").font(.system(size: 36)).foregroundColor(.white)
                    }
                    Button { vm.togglePlay() } label: {
                        ZStack {
                            Circle().fill(Color.cRed).frame(width: 72, height: 72)
                            Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                        }
                    }
                    Button { vm.skip(10) } label: {
                        Image(systemName: "goforward.10").font(.system(size: 36)).foregroundColor(.white)
                    }
                }
                Spacer()
                // Bottom
                VStack(spacing: 10) {
                    ProgressBar(vm: vm).padding(.horizontal, 20)
                    HStack {
                        Text("\(vm.timeStr) / \(vm.durStr)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        if let q = vm.selectedStream {
                            Text(q.displayQuality).font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.gold).clipShape(Capsule())
                        }
                    }.padding(.horizontal, 20)
                }.padding(.bottom, 50)
            }
        }
    }
}

struct ProgressBar: View {
    @ObservedObject var vm: PlayerVM
    @State private var dragging = false
    @State private var dragVal: Double = 0
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.2)).frame(height: dragging ? 6 : 4)
                Capsule().fill(Color.cRed).frame(width: w(geo.size.width), height: dragging ? 6 : 4)
                Circle().fill(Color.white).frame(width: dragging ? 18 : 12, height: dragging ? 18 : 12)
                    .shadow(radius: 4).offset(x: max(0, w(geo.size.width) - (dragging ? 9 : 6)))
            }
            .animation(.spring(response: 0.2), value: dragging)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in dragging = true; dragVal = max(0, min(1, v.location.x / geo.size.width)) * vm.duration }
                .onEnded { _ in vm.player?.seek(to: CMTime(seconds: dragVal, preferredTimescale: 600)); dragging = false }
            )
        }.frame(height: 20)
    }
    private func w(_ total: CGFloat) -> CGFloat {
        guard vm.duration > 0 else { return 0 }
        return CGFloat((dragging ? dragVal : vm.currentTime) / vm.duration) * total
    }
}

// MARK: - Subtitle Settings Sheet
struct SubSettingsSheet: View {
    @ObservedObject var vm: PlayerVM
    @Environment(\.dismiss) var dismiss
    let fonts: [(String, String)] = [
        ("GeezaPro-Bold", "Geeza Pro Bold"),
        ("GeezaPro", "Geeza Pro"),
        ("Helvetica-Bold", "Helvetica Bold"),
        ("Arial-BoldMT", "Arial Bold")
    ]
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardBg.ignoresSafeArea()
                List {
                    Section("Preview") {
                        ZStack {
                            Color.black.clipShape(RoundedRectangle(cornerRadius: 12))
                            Text("مرحباً بك في سينمانا • Welcome to Cinemana New")
                                .font(.custom(vm.subSettings.fontName, size: vm.subSettings.fontSize))
                                .foregroundColor(Color(hex: vm.subSettings.textColor))
                                .multilineTextAlignment(.center).padding(10)
                                .background(Color(hex: "#000000").opacity(vm.subSettings.bgOpacity)
                                    .clipShape(RoundedRectangle(cornerRadius: 6)))
                        }.frame(height: 80)
                    }.listRowBackground(Color.surface)

                    Section("Track") {
                        Toggle("Show Subtitles", isOn: $vm.subSettings.isEnabled).tint(.cRed)
                        if !vm.subs.isEmpty {
                            ForEach(vm.subs, id: \.url) { s in
                                Button {
                                    vm.loadSub(s)
                                } label: {
                                    HStack {
                                        Text(s.displayName).foregroundColor(.textPri)
                                        Spacer()
                                        if vm.selectedSub?.url == s.url {
                                            Image(systemName: "checkmark").foregroundColor(.cRed)
                                        }
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }.listRowBackground(Color.surface)

                    Section("Font") {
                        Picker("Font", selection: $vm.subSettings.fontName) {
                            ForEach(fonts, id: \.0) { Text($1).tag($0) }
                        }.tint(.cRed)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("Size"); Spacer()
                                Text("\(Int(vm.subSettings.fontSize))pt").foregroundColor(.cRed).font(.system(size: 14, weight: .semibold)) }
                            Slider(value: $vm.subSettings.fontSize, in: 12...36, step: 1).tint(.cRed)
                        }
                    }.listRowBackground(Color.surface)

                    Section("Position") {
                        Picker("Position", selection: $vm.subSettings.position) {
                            ForEach(SubtitleSettings.Position.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("Offset"); Spacer()
                                Text("\(Int(vm.subSettings.offsetY))px").foregroundColor(.cRed).font(.system(size: 14, weight: .semibold)) }
                            Slider(value: $vm.subSettings.offsetY, in: 0...120, step: 4).tint(.cRed)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("Background"); Spacer()
                                Text("\(Int(vm.subSettings.bgOpacity * 100))%").foregroundColor(.cRed).font(.system(size: 14, weight: .semibold)) }
                            Slider(value: $vm.subSettings.bgOpacity, in: 0...1, step: 0.1).tint(.cRed)
                        }
                    }.listRowBackground(Color.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Subtitle Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { vm.saveSubSettings(); dismiss() }.fontWeight(.bold).foregroundColor(.cRed)
                }
            }
        }
    }
}
