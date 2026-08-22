import SwiftUI

struct SearchView: View {
    @ObservedObject var vm: HomeViewModel
    @State private var query = ""
    @State private var filter = 0  // 0=All, 1=Movies, 2=Series

    private var filtered: [VideoItem] {
        switch filter {
        case 1: return vm.searchResults.filter { $0.isMovie }
        case 2: return vm.searchResults.filter { $0.isSeries }
        default: return vm.searchResults
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Filter bar — like original app
                HStack(spacing: 0) {
                    FilterChip(title: "All",    selected: filter == 0) { filter = 0 }
                    FilterChip(title: "Movies", selected: filter == 1) { filter = 1 }
                    FilterChip(title: "Series", selected: filter == 2) { filter = 2 }
                }
                .padding(.horizontal).padding(.vertical, 8)

                Divider()

                if vm.isLoading {
                    Spacer(); ProgressView("Searching…"); Spacer()
                } else if filtered.isEmpty && vm.isSearching {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundColor(.secondary)
                        Text("No results for \"\(query)\"").foregroundColor(.secondary)
                    }
                    Spacer()
                } else if vm.searchResults.isEmpty && !vm.isSearching {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "popcorn.fill").font(.system(size: 50)).foregroundColor(.secondary)
                        Text("Search movies & series").font(.headline).foregroundColor(.secondary)
                        Text("Try: action, drama, comedy…").font(.subheadline).foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()
                } else {
                    List(filtered) { item in
                        NavigationLink(destination: DetailView(video: item)) {
                            SearchRow(item: item)
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparatorTint(Color(.systemGray5))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Movies, series, actors…")
            .onChange(of: query, perform: { v in
                if v.isEmpty { vm.clearSearch() }
            })
            .onSubmit(of: .search) {
                let type = filter == 2 ? "series" : "movie"
                vm.search(query: query, type: type)
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline).fontWeight(selected ? .bold : .regular)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(selected ? Color.red : Color(.systemGray6))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(20)
        }
        .padding(.trailing, 6)
    }
}

// MARK: - Search Row (matches original app layout)
struct SearchRow: View {
    let item: VideoItem
    var body: some View {
        HStack(spacing: 12) {
            // Text left
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayTitle)
                    .font(.subheadline).bold()
                    .lineLimit(2)

                // Genre / year
                HStack(spacing: 6) {
                    if let yr = item.year {
                        Text(yr).font(.caption).foregroundColor(.secondary)
                    }
                    if let g = item.genre ?? item.arGenre, !g.isEmpty {
                        Text(g).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                }

                // IMDb badge + type badge
                HStack(spacing: 8) {
                    if let score = item.imdbScore {
                        IMDbBadge(score: score)
                    }
                    TypeBadge(isMovie: item.isMovie, isSeries: item.isSeries)
                }
            }

            Spacer()

            // Poster right (like original)
            AsyncImage(url: item.thumbURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color(.systemGray5).overlay(Image(systemName: "film").foregroundColor(.secondary))
                }
            }
            .frame(width: 80, height: 110).clipped().cornerRadius(8)
        }
    }
}

// MARK: - IMDb Badge
struct IMDbBadge: View {
    let score: String
    var body: some View {
        HStack(spacing: 3) {
            Text("IMDb")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.black)
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(Color.yellow)
                .cornerRadius(3)
            Text(score)
                .font(.caption).bold()
                .foregroundColor(.yellow)
        }
    }
}

// MARK: - Type Badge
struct TypeBadge: View {
    let isMovie: Bool
    let isSeries: Bool
    var body: some View {
        if isMovie || isSeries {
            Text(isMovie ? "Movie" : "Series")
                .font(.caption2).bold()
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(isMovie ? Color.blue : Color.purple)
                .cornerRadius(6)
        }
    }
}
