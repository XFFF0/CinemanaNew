import SwiftUI

struct SearchView: View {
    @ObservedObject var vm: HomeViewModel
    @State private var query = ""
    @State private var type = "movie"

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Type", selection: $type) {
                    Text("Movies").tag("movie")
                    Text("Series").tag("series")
                }.pickerStyle(.segmented).padding()

                if vm.isLoading {
                    Spacer(); ProgressView("Searching…"); Spacer()
                } else if vm.searchResults.isEmpty && vm.isSearching {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundColor(.secondary)
                        Text("No results for \"\(query)\"").foregroundColor(.secondary)
                    }
                    Spacer()
                } else if vm.searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "popcorn").font(.system(size: 50)).foregroundColor(.secondary)
                        Text("Search movies & series").foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(vm.searchResults) { item in
                        NavigationLink(destination: DetailView(video: item)) {
                            SearchRow(item: item)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }.listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search movies & series")
            .onChange(of: query) { v in if v.isEmpty { vm.clearSearch() } }
            .onSubmit(of: .search) { vm.search(query: query, type: type) }
            .onChange(of: type) { _ in if !query.isEmpty { vm.search(query: query, type: type) } }
        }
    }
}

struct SearchRow: View {
    let item: VideoItem
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.thumbURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color(.systemGray5).overlay(Image(systemName: "film").foregroundColor(.secondary))
                }
            }
            .frame(width: 60, height: 85).clipped().cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle).font(.subheadline).bold().lineLimit(2)
                HStack(spacing: 8) {
                    if let yr = item.year { Label(yr, systemImage: "calendar").font(.caption).foregroundColor(.secondary) }
                    if let st = item.stars, st != "0" { Label(st, systemImage: "star.fill").font(.caption).foregroundColor(.yellow) }
                }
                Text(item.isMovie ? "Movie" : item.isSeries ? "Series" : "")
                    .font(.caption2).bold().foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(item.isMovie ? Color.blue : Color.purple).cornerRadius(4)
            }
            Spacer()
        }
    }
}
