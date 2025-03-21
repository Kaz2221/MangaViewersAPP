//
//  ContentView.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-03-15.
//

import SwiftUI

struct ContentView: View {
    @State private var seriesList: [Series] = []
    @State private var coverImages: [String: UIImage] = [:] // Cache pour les couvertures

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                    ForEach(seriesList) { series in
                        // Modification ici : MangaDetailView au lieu de BookListView
                        NavigationLink(destination: MangaDetailView(series: series)) {
                            VStack {
                                if let image = coverImages[series.id] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 180)
                                        .cornerRadius(8)
                                } else {
                                    ProgressView()
                                        .frame(width: 120, height: 180)
                                        .onAppear {
                                            fetchCover(for: series)
                                        }
                                }

                                Text(series.name)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 120)
                                    .padding(.top, 5)

                                Text("\(series.booksCount) books")
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
            .navigationTitle("Manga Series")
            .onAppear {
                fetchData()
            }
        }
    }

    private func fetchData() {
        APIService().fetchSeries { series in
            DispatchQueue.main.async {
                if let series = series {
                    self.seriesList = series
                } else {
                    print("API request failed!")
                    
                    // Ajouter des données de test en cas d'échec
                    self.seriesList = [
                        Series(id: "test1", libraryId: "lib1", name: "One Piece", booksCount: 10),
                        Series(id: "test2", libraryId: "lib1", name: "Naruto", booksCount: 8),
                        Series(id: "test3", libraryId: "lib1", name: "Dragon Ball", booksCount: 12)
                    ]
                }
            }
        }
    }

    private func fetchCover(for series: Series) {
        APIService().fetchSeriesCover(seriesId: series.id) { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.coverImages[series.id] = image
                }
            }
        }
    }
}

// Utiliser l'ancienne syntaxe pour la prévisualisation
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
