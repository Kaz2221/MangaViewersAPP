import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var apiService = APIService()
    @State private var searchText = ""
    @State private var selectedGenres: Set<String> = []
    
    // Genres populaires de manga
    // Utilisons les genres de l'API au lieu d'une liste codée en dur
    var genres: [String] {
        // Si aucun genre n'est disponible, utiliser une liste par défaut
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
                
                // Filtres par genre (scrollable horizontalement)
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
                
                // Indicateur des filtres actifs
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
                            NavigationLink(destination: MangaDetailView(series: Series(id: manga.id, libraryId: "", name: manga.title, booksCount: 0))) {
                                SearchResultRow(manga: manga)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Recherche")
            .onAppear {
                // Chargement initial des mangas populaires
                viewModel.loadPopularManga()
            }
        }
    }
}

// Bouton de genre
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

// Ligne de résultat de recherche
struct SearchResultRow: View {
    let manga: MangaSearchResult
    @State private var coverImage: UIImage?
    let apiService = APIService()
    
    var body: some View {
        HStack(spacing: 15) {
            // Image de couverture
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
            
            // Informations du manga
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
                
                HStack(spacing: 15) {
                    if let status = manga.status {
                        Text(status)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
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
    
    // Fonction pour charger l'image de couverture
    private func loadCoverImage() {
        // Utiliser directement l'API pour charger l'image
        apiService.fetchSeriesCover(seriesId: manga.id) { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.coverImage = image
                }
            }
        }
    }
}

// Écran de détails du manga sélectionné
struct MangaDetailsView: View {
    let manga: MangaSearchResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Entête avec image et informations de base
                HStack(alignment: .top, spacing: 16) {
                    // Image de couverture
                    if let imageUrl = manga.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 130, height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 130, height: 200)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 130, height: 200)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 130, height: 200)
                            }
                        }
                        .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 130, height: 200)
                            .cornerRadius(8)
                    }
                    
                    // Informations principales
                    VStack(alignment: .leading, spacing: 8) {
                        Text(manga.title)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if let author = manga.author, !author.isEmpty {
                            Text("Par \(author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let score = manga.score {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", score))
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let status = manga.status {
                            Text(status)
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    status == "En cours" ? Color.green.opacity(0.2) :
                                    status == "Terminé" ? Color.orange.opacity(0.2) :
                                    Color.gray.opacity(0.2)
                                )
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Section Synopsis
                if let synopsis = manga.synopsis, !synopsis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis")
                            .font(.headline)
                        
                        Text(synopsis)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }
                
                // Section Genres
                if let genres = manga.genres, !genres.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Genres")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Autres informations
                if let published = manga.publishedDate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Informations")
                            .font(.headline)
                        
                        HStack {
                            Text("Publié:")
                                .fontWeight(.medium)
                            Text(published)
                        }
                        .font(.subheadline)
                    }
                }
                
                // Bouton d'action principal
                Button(action: {
                    // Action pour lire ou accéder au manga
                }) {
                    Text("Lire ce manga")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Mise en page en flux (comme des tags qui s'adaptent à la largeur)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var height: CGFloat = 0
        let rows = computeRows(containerWidth: containerWidth, subviews: subviews)
        
        for row in rows {
            if let maxHeight = row.map({ subviews[$0].sizeThatFits(.unspecified).height }).max() {
                height += maxHeight + spacing
            }
        }
        
        return CGSize(width: containerWidth, height: max(0, height - spacing))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(containerWidth: bounds.width, subviews: subviews)
        
        var y = bounds.minY
        
        for row in rows {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            
            for index in row {
                let subview = subviews[index]
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: subviewSize.width, height: rowHeight)
                )
                
                x += subviewSize.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(containerWidth: CGFloat, subviews: Subviews) -> [[Int]] {
        var rows: [[Int]] = [[]]
        var currentRow = 0
        var remainingWidth = containerWidth
        
        for index in subviews.indices {
            let subviewSize = subviews[index].sizeThatFits(.unspecified)
            
            if subviewSize.width > remainingWidth {
                // Start new row
                currentRow += 1
                rows.append([])
                remainingWidth = containerWidth
            }
            
            rows[currentRow].append(index)
            remainingWidth -= subviewSize.width + spacing
        }
        
        return rows
    }
}

// Aperçu pour SwiftUI
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
