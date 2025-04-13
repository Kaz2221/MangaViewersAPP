import SwiftUI
import Combine
import FirebaseAuth

struct MangaDetailView: View {
    let series: Series
    let apiService: APIService // ← Ajout ici

    @StateObject private var viewModel = MangaDetailViewModel()
    @StateObject private var favoritesService = FavoritesService()
    @ObservedObject var authService = AuthenticationService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Affichage des informations Jikan (en ligne)
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Recherche d'informations...")
                        Spacer()
                    }
                    .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Réessayer") {
                            viewModel.searchByTitle(title: series.name)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else if let manga = viewModel.mangaDetails {
                    JikanMangaDetailsSection(manga: manga)
                } else {
                    Text("Recherche d'informations en ligne...")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Divider()
                    .padding(.vertical)
                
                // Liste des chapitres (votre API locale)
                VStack(alignment: .leading) {
                    Text("Chapitres")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    ChapterListSection(series: series, apiService: apiService) // ← Passage de l'instance
                }
            }
            .padding()
        }
        .navigationTitle(series.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Group {
                if authService.isAuthenticated {
                    Button(action: {
                        toggleFavorite()
                    }) {
                        Image(systemName: favoritesService.isFavorite(seriesId: series.id) ? "heart.fill" : "heart")
                            .foregroundColor(favoritesService.isFavorite(seriesId: series.id) ? .red : .gray)
                    }
                }
            }
        )
        .onAppear {
            viewModel.searchByTitle(title: series.name)
            
            // Initialize favorites when view appears
            if authService.isAuthenticated, let userId = Auth.auth().currentUser?.uid {
                favoritesService.startListening(forUserId: userId)
            }
        }
    }
    
    private func toggleFavorite() {
        guard authService.isAuthenticated, let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        if favoritesService.isFavorite(seriesId: series.id) {
            // Remove from favorites
            favoritesService.removeFavorite(seriesId: series.id) { error in
                if let error = error {
                    print("Error removing favorite: \(error.localizedDescription)")
                }
            }
        } else {
            // Add to favorites
            favoritesService.addFavorite(series: series, userId: userId) { error in
                if let error = error {
                    print("Error adding favorite: \(error.localizedDescription)")
                }
            }
        }
    }
}
