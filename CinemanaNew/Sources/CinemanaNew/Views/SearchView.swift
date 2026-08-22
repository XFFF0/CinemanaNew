import SwiftUI

struct SearchView: View {
    @ObservedObject var vm: HomeViewModel
    @State private var query = ""
    @State private var type = "movie"

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Type picker
                Picker("Type", selection: $type) {
                    Text("Movies").tag("movie")
                    Text("Series").tag("series")
                }
                .pickerStyle(.segmented)
                .padding()

                // Results
                if vm.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if vm.searchResults.isEmpty && vm.isSearching {
                    Spacer()
                    Text("No results found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(vm.searchResults) { item in
                        NavigationLink(destination: DetailView(video: item)) {
                            SearchResultRow(item: item)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search movies & series")
            .onChange(of: query) { newVal in
                if newVal.isEmpty { vm.clearSearch() }
            }
            .onSubmit(of: .search) {
                vm.search(query: query, type: type)
            }
            .onChange(of: type) { _ in
                if !query.isEmpty { vm.search(query: query, type: type) }
            }
        }
    }
}

struct SearchResultRow: View {
    let item: VideoItem
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.imgThumbObjUrl ?? "")) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.gray.opacity(0.3)
                    .overlay(Image(systemName: "film").foregroundColor(.white))
                }
            }
            .frame(width: 60, height: 85)
            .clipped()
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.subheadline).bold()
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let year = item.year {
                        Label(year, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let stars = item.stars {
                        Label(stars, systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                Text(item.isMovie ? "Movie" : item.isSeries ? "Series" : "")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(item.isMovie ? Color.blue : Color.purple)
                    .cornerRadius(4)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
