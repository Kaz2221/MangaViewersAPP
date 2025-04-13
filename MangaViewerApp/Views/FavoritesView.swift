//
//  FavoritesView.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-04-11.
//
import SwiftUI
import FirebaseAuth

struct FavoritesView: View {
    @StateObject private var favoritesService = FavoritesService()
    @StateObject private var apiService = APIService()
    @ObservedObject var authService = AuthenticationService()
    
    @State private var coverImages: [String: UIImage] = [:]
    
    var body: some View {
        NavigationView {
            Group {
                if !authService.isAuthenticated {
                    // User not logged in
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "heart.slash")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                        
                        Text("Connectez-vous pour voir vos favoris")
                            .font(.headline)
                        
                        NavigationLink(destination: LoginView(authService: authService)) {
                            Text("Se connecter")
                                .padding()
                                .frame(width: 200)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                } else if favoritesService.isLoading {
                    // Loading state
                    VStack {
                        Spacer()
                        ProgressView("Chargement des favoris...")
                        Spacer()
                    }
                } else if favoritesService.favorites.isEmpty {
                    // No favorites
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "heart")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                        
                        Text("Vous n'avez pas encore de favoris")
                            .font(.headline)
                        
                        Text("Explorez des mangas et ajoutez-les à vos favoris")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: ContentView()) {
                            Text("Explorer les mangas")
                                .padding()
                                .frame(width: 200)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Display favorites
                    List {
                        ForEach(favoritesService.favorites) { favorite in
                            NavigationLink(
                                destination: MangaDetailView(
                                    series: Series(
                                        id: favorite.seriesId,
                                        libraryId: "",
                                        name: favorite.seriesName,
                                        booksCount: 0
                                    ),
                                    apiService: apiService
                                )
                            ) {
                                HStack {
                                    if let image = coverImages[favorite.seriesId] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 90)
                                            .cornerRadius(6)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 90)
                                            .cornerRadius(6)
                                            .onAppear {
                                                loadCoverImage(for: favorite.seriesId)
                                            }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(favorite.seriesName)
                                            .font(.headline)
                                        
                                        Text("Ajouté le \(formatDate(favorite.dateAdded))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 8)
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    removeFromFavorites(favorite.seriesId)
                                } label: {
                                    Label("Retirer", systemImage: "heart.slash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favoris")
            .onAppear {
                if authService.isAuthenticated, let userId = Auth.auth().currentUser?.uid {
                    favoritesService.startListening(forUserId: userId)
                }
            }
            .onChange(of: authService.isAuthenticated) { isAuthenticated in
                if isAuthenticated, let userId = Auth.auth().currentUser?.uid {
                    favoritesService.startListening(forUserId: userId)
                } else {
                    favoritesService.removeListener()
                }
            }
            .alert(isPresented: .constant(favoritesService.errorMessage != nil)) {
                Alert(
                    title: Text("Erreur"),
                    message: Text(favoritesService.errorMessage ?? ""),
                    dismissButton: .default(Text("OK")) {
                        favoritesService.errorMessage = nil
                    }
                )
            }
        }
    }
    
    private func loadCoverImage(for seriesId: String) {
        apiService.fetchSeriesCover(seriesId: seriesId) { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.coverImages[seriesId] = image
                }
            }
        }
    }
    
    private func removeFromFavorites(_ seriesId: String) {
        favoritesService.removeFavorite(seriesId: seriesId) { error in
            if let error = error {
                print("Error removing favorite: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
