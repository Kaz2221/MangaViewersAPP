import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var apiService = APIService()
    @State private var searchText = ""
    @State private var selectedGenres: Set<String> = []
    
    var genres: [String] {
        if viewModel.availableGenres.isEmpty {
            return [
                "Action", "Adventure", "Comedy", "Drama", "Fantasy",
                "Horror", "Mystery", "Romance", "Sci-Fi", "Slice of Life",
                "Sports", "Supernatural", "Thriller"
            ]
        }
        return viewModel.availableGenres
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barre de recherche
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Rechercher un manga...", text: $searchText)
                        .onChange(of: searchText) { _ in
                            viewModel.searchManga(query: searchText, genres: Array(selectedGenres))
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchManga(query: "", genres: Array(selectedGenres))
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Filtres par genre
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(genres, id: \.self) { genre in
                            GenreButton(
                                genre: genre,
                                isSelected: selectedGenres.contains(genre),
                                action: {
                                    if selectedGenres.contains(genre) {
                                        selectedGenres.remove(genre)
                                    } else {
                                        selectedGenres.insert(genre)
                                    }
                                    viewModel.searchManga(query: searchText, genres: Array(selectedGenres))
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                if !selectedGenres.isEmpty {
                    HStack {
                        Text("Filtres actifs:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(selectedGenres), id: \.self) { genre in
                                    HStack(spacing: 4) {
                                        Text(genre)
                                            .font(.caption)
                                        
                                        Button(action: {
                                            selectedGenres.remove(genre)
                                            viewModel.searchManga(query: searchText, genres: Array(selectedGenres))
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8))
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedGenres.removeAll()
                            viewModel.searchManga(query: searchText, genres: [])
                        }) {
                            Text("Effacer")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                Divider()
                
                // Résultats de recherche
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Recherche en cours...")
                    Spacer()
                } else if viewModel.results.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty && selectedGenres.isEmpty
                             ? "Commencez à chercher des mangas"
                             : "Aucun manga trouvé")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty || !selectedGenres.isEmpty {
                            Text("Essayez d'autres termes ou filtres")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.results) { manga in
                            NavigationLink(destination:
                                MangaDetailView(
                                    series: Series(id: manga.id, libraryId: "", name: manga.title, booksCount: 0),
                                    apiService: apiService
                                )
                            ) {
                                SearchResultRow(manga: manga)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Recherche")
            .showTabBar(true) // Replace with our custom environment modifier
            .onAppear {
                viewModel.loadPopularManga()
            }
        }
    }
}

// Composants auxiliaires

struct GenreButton: View {
    let genre: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(genre)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct SearchResultRow: View {
    let manga: MangaSearchResult
    @State private var coverImage: UIImage?
    let apiService = APIService()
    
    var body: some View {
        HStack(spacing: 15) {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 100)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 70, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                    )
                    .onAppear {
                        loadCoverImage()
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let author = manga.author, !author.isEmpty {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let status = manga.status {
                    Text(status)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if let genres = manga.genres, !genres.isEmpty {
                    Text(genres.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func loadCoverImage() {
        apiService.fetchSeriesCover(seriesId: manga.id) { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.coverImage = image
                }
            }
        }
    }
}

// Aperçu
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
