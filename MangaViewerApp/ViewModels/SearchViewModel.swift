import Foundation
import UIKit
import Combine

// Modèle pour les résultats de recherche
struct MangaSearchResult: Identifiable {
    let id: String
    let title: String
    let imageUrl: String?
    let author: String?
    let score: Double?
    let status: String?
    let genres: [String]?
    let synopsis: String?
    let publishedDate: String?
}

class SearchViewModel: ObservableObject {
    @Published var results: [MangaSearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // Garde en mémoire toutes les séries chargées
    private var allSeries: [Series] = []
    // Garde en mémoire les métadonnées (genres, etc.)
    private var seriesMetadata: [String: [String]] = [:]
    // Liste des genres uniques disponibles dans l'API
    @Published var availableGenres: [String] = []
    
    init() {
        // Charger toutes les séries au démarrage
        loadAllSeries()
        // Charger les genres disponibles
        loadAvailableGenres()
    }
    
    // Fonction pour rechercher des mangas avec un texte et des genres
    func searchManga(query: String, genres: [String]) {
        isLoading = true
        errorMessage = nil
        
        // Si la liste est vide, charger d'abord toutes les séries
        if allSeries.isEmpty {
            loadAllSeries()
            return
        }
        
        // Filtrer les mangas en fonction du texte et des genres
        DispatchQueue.main.async {
            // Convertir les Series en MangaSearchResult pour l'affichage
            let filteredResults = self.allSeries
                .filter { series in
                    // Vérifier si le titre contient la requête (si non vide)
                    let titleMatches = query.isEmpty ||
                        series.name.localizedCaseInsensitiveContains(query)
                    
                    // Vérifier les genres si des genres sont sélectionnés
                    var genreMatches = genres.isEmpty
                    
                    if !genres.isEmpty, let seriesGenres = self.seriesMetadata[series.id] {
                        genreMatches = seriesGenres.contains { seriesGenre in
                            genres.contains { selectedGenre in
                                seriesGenre.localizedCaseInsensitiveContains(selectedGenre)
                            }
                        }
                    }
                    
                    return titleMatches && genreMatches
                }
                .map { series in
                    // Convertir Series en MangaSearchResult
                    self.convertToSearchResult(series)
                }
            
            self.isLoading = false
            self.results = filteredResults
        }
    }
    
    // Charger toutes les séries disponibles
    private func loadAllSeries() {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchSeries { [weak self] series in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let series = series {
                    self.allSeries = series
                    // Une fois toutes les séries chargées, les afficher
                    self.results = series.map { self.convertToSearchResult($0) }
                    self.isLoading = false
                    
                    // Charger les métadonnées pour chaque série (ex: genres)
                    for serie in series {
                        self.loadSeriesMetadata(seriesId: serie.id)
                    }
                } else {
                    self.errorMessage = "Impossible de charger les mangas"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Charger les genres disponibles depuis l'API Jikan
    private func loadAvailableGenres() {
        guard let url = URL(string: "https://api.jikan.moe/v4/genres/manga") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                return
            }
            
            do {
                // Structure pour décoder la réponse de l'API Jikan pour les genres
                struct GenresResponse: Decodable {
                    let data: [Genre]
                    
                    struct Genre: Decodable {
                        let name: String
                    }
                }
                
                let response = try JSONDecoder().decode(GenresResponse.self, from: data)
                
                DispatchQueue.main.async {
                    // Extraire les noms des genres
                    self.availableGenres = response.data.map { $0.name }
                }
            } catch {
                print("Erreur de décodage des genres: \(error)")
            }
        }.resume()
    }
    
    // Charger les métadonnées d'une série en utilisant l'API Jikan
    private func loadSeriesMetadata(seriesId: String) {
        // Trouver la série dans la liste
        guard let series = allSeries.first(where: { $0.id == seriesId }) else {
            return
        }
        
        // Encoder le nom de la série pour l'URL
        guard let encodedName = series.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        // URL de recherche par titre sur Jikan
        let urlString = "https://api.jikan.moe/v4/manga?q=\(encodedName)&limit=1"
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                return
            }
            
            do {
                // Décoder la réponse
                let response = try JSONDecoder().decode(MangaListResponse.self, from: data)
                
                if let manga = response.data.first {
                    // Récupérer les genres
                    let genres = manga.genres?.map { $0.name } ?? []
                    
                    DispatchQueue.main.async {
                        // Stocker les genres trouvés
                        self.seriesMetadata[seriesId] = genres
                        
                        // Mettre à jour les résultats pour refléter les nouveaux genres
                        if self.results.contains(where: { $0.id == seriesId }) {
                            self.searchManga(query: "", genres: [])
                        }
                    }
                }
            } catch {
                print("Erreur lors de la recherche des métadonnées: \(error)")
            }
        }.resume()
    }
    
    // Convertir une Series en MangaSearchResult pour l'affichage
    private func convertToSearchResult(_ series: Series) -> MangaSearchResult {
        // Construire l'URL de l'image
        let imageUrl = "\(apiService.activeBaseURL)/series/\(series.id)/thumbnail"
        
        // Récupérer les genres de la série s'ils existent déjà
        let genres = seriesMetadata[series.id]
        
        return MangaSearchResult(
            id: series.id,
            title: series.name,
            imageUrl: imageUrl,
            author: nil, // À implémenter si disponible dans Komga
            score: nil,  // À implémenter si disponible dans Komga
            status: "Volumes disponibles: \(series.booksCount)",
            genres: genres,
            synopsis: nil, // À implémenter si disponible dans Komga
            publishedDate: nil // À implémenter si disponible dans Komga
        )
    }
    
    func loadCoverImage(for mangaId: String, completion: @escaping (UIImage?) -> Void) {
        // Vérifier que l'ID est valide
        guard !mangaId.isEmpty else {
            completion(nil)
            return
        }
        
        // Utiliser l'APIService pour récupérer l'image
        apiService.fetchSeriesCover(seriesId: mangaId) { image in
            // Retourner l'image dans le completion handler
            completion(image)
        }
    }

    
    // Charger les mangas populaires (pour l'affichage initial)
    func loadPopularManga() {
        // Pour Komga, nous chargeons simplement toutes les séries
        // puisque nous n'avons pas de notion de "popularité"
        if allSeries.isEmpty {
            loadAllSeries()
        } else {
            // Si déjà chargé, juste mettre à jour les résultats
            DispatchQueue.main.async {
                self.results = self.allSeries.map { self.convertToSearchResult($0) }
            }
        }
    }
    
    // Structure pour décoder la réponse de l'API Jikan pour les mangas
    struct MangaListResponse: Decodable {
        let data: [MangaData]
    }

    struct MangaData: Decodable {
        let title: String
        let genres: [MangaGenre]?
        
        struct MangaGenre: Decodable {
            let name: String
        }
    }
}


