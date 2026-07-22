import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Cinemana").font(.largeTitle.bold())

            TextField("البريد الإلكتروني", text: $vm.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)

            SecureField("كلمة المرور", text: $vm.password)
                .textFieldStyle(.roundedBorder)

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Button {
                Task { await vm.login() }
            } label: {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text("تسجيل الدخول").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.email.isEmpty || vm.password.isEmpty || vm.isLoading)

            Spacer()
        }
        .padding()
    }
}

struct VideoDetailView: View {
    let videoId: String
    @StateObject private var vm = VideoDetailViewModel()

    var body: some View {
        ScrollView {
            if vm.isLoading {
                ProgressView().padding(.top, 60)
            } else if let video = vm.video {
                VStack(alignment: .leading, spacing: 12) {
                    AsyncImage(url: URL(string: video.imgObjUrl ?? "")) { $0.resizable().scaledToFit() } placeholder: { Color.gray.opacity(0.2) }

                    Text(video.title).font(.title2.bold())

                    if let year = video.year, let duration = video.duration {
                        Text("\(year) · \(duration)").font(.subheadline).foregroundStyle(.secondary)
                    }

                    if let content = video.arContent ?? video.enContent {
                        Text(content).font(.body)
                    }

                    if let best = vm.bestQuality, let url = URL(string: best.url) {
                        NavigationLink(destination: VideoPlayerView(url: url, skip: video.skippingDurations)) {
                            Label("تشغيل", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    if !vm.seasons.isEmpty {
                        Text("الحلقات").font(.headline)
                        VideoRow(title: "", videos: vm.seasons)
                    }

                    if !vm.comments.isEmpty {
                        Text("التعليقات").font(.headline)
                        ForEach(vm.comments) { comment in
                            VStack(alignment: .leading) {
                                Text(comment.userName ?? "").font(.caption.bold())
                                Text(comment.comment ?? "").font(.caption)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
            }
        }
        .task { await vm.load(videoId: videoId) }
        .navigationBarTitleDisplayMode(.inline)
    }
}
