import SwiftUI

struct WatchLaterView: View {
   @EnvironmentObject var watchLaterManager: WatchLaterManager

   var body: some View {
       NavigationStack {
           ZStack {
               Color.appBackground
                   .ignoresSafeArea()

               if watchLaterManager.watchLaterItems.isEmpty {
                   EmptyStateView(
                       icon: "bookmark",
                       title: "No Videos",
                       message: "Videos you add to watch later will appear here"
                   )
               } else {
                   ScrollView {
                       LazyVStack(spacing: 16) {
                           ForEach(watchLaterManager.watchLaterItems) { item in
                               NavigationLink(destination: VideoDetailView(video: VideoModel(
                                   nb: item.videoId,
                                   arTitle: item.title,
                                   enTitle: item.title,
                                   kind: item.kind,
                                   imgObjUrl: item.thumbnailUrl,
                                   imgThumbObjUrl: item.thumbnailUrl
                               ))) {
                                   WatchLaterItemRow(item: item)
                               }
                           }
                       }
                       .padding()
                   }
               }
           }
           .navigationTitle("Watch Later")
           .navigationBarTitleDisplayMode(.large)
           .toolbarBackground(Color.appBackground, for: .navigationBar)
           .toolbarColorScheme(.dark, for: .navigationBar)
       }
   }
}

struct WatchLaterItemRow: View {
   let item: WatchLaterItem

   var body: some View {
       HStack(spacing: 12) {
           KFImage(URL(string: item.thumbnailUrl ?? ""))
               .resizable()
               .aspectRatio(16/9, contentMode: .fill)
               .frame(width: 120, height: 70)
               .cornerRadius(8)
               .clipped()

           VStack(alignment: .leading, spacing: 4) {
               Text(item.title)
                   .font(.headline)
                   .foregroundColor(.white)
                   .lineLimit(2)

               HStack {
                   Image(systemName: item.isMovie ? "film" : "tv")
                       .font(.caption)

                   Text(item.isMovie ? "Movie" : "Series")
                       .font(.caption)

                   Text("•")
                       .foregroundColor(.white.opacity(0.5))

                   Text(formatDate(item.addedAt))
                       .font(.caption)
                       .foregroundColor(.white.opacity(0.6))
               }
               .foregroundColor(.white.opacity(0.7))
           }

           Spacer()
       }
       .padding()
       .liquidGlass(cornerRadius: 12)
   }

   private func formatDate(_ date: Date) -> String {
       let formatter = DateFormatter()
       formatter.dateStyle = .medium
       return formatter.string(from: date)
   }
}

import Kingfisher

#Preview {
   WatchLaterView()
       .environmentObject(WatchLaterManager.shared)
       .preferredColorScheme(.dark)
}
