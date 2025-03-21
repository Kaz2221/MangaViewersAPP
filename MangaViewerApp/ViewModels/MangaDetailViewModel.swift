import Foundation
import Combine

class MangaDetailViewModel: ObservableObject {
    @Published var mangaDetails: MangaData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchByTitle(title: String) {
        isLoading = true
        errorMessage = nil
        
        // Créer l'URL pour la recherche
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://api.jikan.moe/v4/manga?q=\(encodedTitle)&limit=1") else {
            errorMessage = "URL invalide"
            isLoading = false
            return
        }
        
        // Effectuer la requête
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MangaListResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    self.isLoading = false
                    self.errorMessage = "Erreur: \(error.localizedDescription)"
                }
            } receiveValue: { response in
                if let firstManga = response.data.first {
                    self.fetchDetails(for: firstManga.malId)
                } else {
                    self.isLoading = false
                    self.errorMessage = "Aucun manga trouvé pour ce titre"
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchDetails(for id: Int) {
        guard let url = URL(string: "https://api.jikan.moe/v4/manga/\(id)") else {
            errorMessage = "URL invalide"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MangaResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = "Erreur: \(error.localizedDescription)"
                }
            } receiveValue: { response in
                self.mangaDetails = response.data
            }
            .store(in: &cancellables)
    }
}
