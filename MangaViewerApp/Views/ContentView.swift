import SwiftUI

struct ContentView: View {
    @StateObject private var apiService = APIService() // Utiliser StateObject au lieu de créer une nouvelle instance
    @State private var seriesList: [Series] = []
    @State private var coverImages: [String: UIImage] = [:] // Cache pour les couvertures
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            VStack {
                // Indicateur de chargement
                if isLoading {
                    Spacer()
                    ProgressView("Chargement des séries...")
                    Spacer()
                } else if seriesList.isEmpty {
                    // Message si aucune série n'est trouvée
                    Spacer()
                    VStack {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Aucune série trouvée")
                            .font(.headline)
                        
                        Button(action: {
                            isLoading = true
                            fetchData()
                        }) {
                            Text("Réessayer")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                    Spacer()
                } else {
                    // Affichage des séries de manga
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                            ForEach(seriesList) { series in
                                // Navigation vers MangaDetailView
                                NavigationLink(destination: MangaDetailView(series: series)) {
                                    VStack {
                                        // Image de couverture
                                        if let image = coverImages[series.id] {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 180)
                                                .cornerRadius(8)
                                        } else {
                                            // Placeholder pendant le chargement
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 120, height: 180)
                                                .cornerRadius(8)
                                                .overlay(
                                                    ProgressView()
                                                        .scaleEffect(0.7)
                                                )
                                                .onAppear {
                                                    fetchCover(for: series)
                                                }
                                        }

                                        // Titre de la série
                                        Text(series.name)
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: 120)
                                            .padding(.top, 5)

                                        // Nombre de volumes
                                        Text("\(series.booksCount) volumes")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 5)
                                    }
                                    .frame(width: 140)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        // Support du Pull-to-refresh
                        fetchData()
                    }
                }
            }
            .navigationTitle("Manga Series")
            .onAppear {
                if seriesList.isEmpty {
                    fetchData()
                }
            }
        }
    }

    private func fetchData() {
        isLoading = true
        print("Début fetchData()")
        
        // Utiliser l'instance apiService existante au lieu d'en créer une nouvelle
        apiService.fetchSeries { series in
            print("Callback fetchSeries appelé")
            DispatchQueue.main.async {
                isLoading = false
                
                if let series = series {
                    print("Séries reçues : \(series.count)")
                    self.seriesList = series
                } else {
                    print("API request failed!")
                    
                    // Données de test en cas d'échec
                    print("Ajout de données de test")
                    self.seriesList = [
                        Series(id: "test1", libraryId: "lib1", name: "One Piece", booksCount: 10),
                        Series(id: "test2", libraryId: "lib1", name: "Naruto", booksCount: 8),
                        Series(id: "test3", libraryId: "lib1", name: "Dragon Ball", booksCount: 12)
                    ]
                    print("Nombre d'éléments dans seriesList après ajout des tests : \(self.seriesList.count)")
                }
            }
        }
    }

    private func fetchCover(for series: Series) {
        // Éviter de charger plusieurs fois la même image
        guard coverImages[series.id] == nil else { return }
        
        // Utiliser l'instance apiService existante
        apiService.fetchSeriesCover(seriesId: series.id) { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.coverImages[series.id] = image
                }
            }
        }
    }
}

// Prévisualisation SwiftUI
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
