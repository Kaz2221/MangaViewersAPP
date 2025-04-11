import SwiftUI

// Composants pour les sections de détails
struct JikanMangaDetailsSection: View {
    let manga: MangaData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: URL(string: manga.images.jpg.largeImageUrl ?? manga.images.jpg.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .frame(width: 130, height: 200)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(manga.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if let japaneseTitle = manga.titleJapanese {
                        Text(japaneseTitle)
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
                                status == "Publishing" ? Color.green.opacity(0.2) :
                                status == "Finished" ? Color.orange.opacity(0.2) : Color.gray.opacity(0.2)
                            )
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.bottom, 8)
            
            Group {
                Text("Informations")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                if let published = manga.published {
                    DetailRow(label: "Publication", value: published.formattedDateRange)
                }
                
                if let authors = manga.authors, !authors.isEmpty {
                    DetailRow(label: "Auteur(s)", value: authors.map { $0.name }.joined(separator: ", "))
                }
                
                if let genres = manga.genres, !genres.isEmpty {
                    DetailRow(label: "Genres", value: genres.map { $0.name }.joined(separator: ", "))
                }
            }
            
            if let synopsis = manga.synopsis, !synopsis.isEmpty {
                Group {
                    Text("Synopsis")
                        .font(.headline)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                    Text(synopsis)
                        .lineSpacing(4)
                }
            }
        }
    }
}

// Section pour les détails locaux
struct LocalMangaDetailsSection: View {
    let series: Series
    @State private var coverImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130, height: 200)
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 130, height: 200)
                        .cornerRadius(8)
                        .onAppear {
                            fetchCover()
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(series.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(series.booksCount) volumes disponibles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Informations locales limitées. Basculez vers 'Infos en ligne' pour plus de détails.")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    private func fetchCover() {
        APIService().fetchSeriesCover(seriesId: series.id) { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.coverImage = image
                }
            }
        }
    }
}

// ✅ Section pour la liste des chapitres – MODIFIÉE
struct ChapterListSection: View {
    let series: Series
    let apiService: APIService // ← Ajouté
    @State private var books: [Book] = []

    var body: some View {
        VStack {
            if books.isEmpty {
                ProgressView("Chargement des chapitres...")
                    .padding()
            } else {
                ForEach(books) { book in
                    NavigationLink(destination: ReaderView(book: book)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(book.name)
                                    .font(.headline)
                                
                                Text("\(book.pagesCount) pages")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "book")
                                .foregroundColor(.blue)
                                .padding(.trailing, 8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            print("ChapterListSection: View appeared for series: \(series.name)")
            print("ChapterListSection: Series details - ID: \(series.id), libraryId: \(series.libraryId), booksCount: \(series.booksCount)")
            fetchBooks()
        }
    }

    private func fetchBooks() {
        print("ChapterListSection: Fetching books for series: \(series.name), ID: \(series.id)")
        
        apiService.fetchBooks(for: series.id) { fetchedBooks in
            if let fetchedBooks = fetchedBooks {
                print("ChapterListSection: Received \(fetchedBooks.count) books from API")
                DispatchQueue.main.async {
                    self.books = fetchedBooks
                    print("ChapterListSection: Updated books array, now has \(self.books.count) books")
                }
            } else {
                print("ChapterListSection: Received nil books from API for series ID: \(series.id)")
            }
        }
    }
}

// Composant utilitaire pour les lignes de détails
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 90, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}

