import SwiftUI
import Combine

struct MangaDetailView: View {
    let series: Series
    let apiService: APIService // ← Ajout ici

    @StateObject private var viewModel = MangaDetailViewModel()
    
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
        .onAppear {
            viewModel.searchByTitle(title: series.name)
        }
    }
}

