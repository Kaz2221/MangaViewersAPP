import SwiftUI

struct ReaderView: View {
    let book: Book
    @State private var currentPage = 1
    @State private var pageImage: UIImage?
    @State private var isLoading = false
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Affichage de l'image
                if let image = pageImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: dragOffset)
                        .animation(.spring(), value: dragOffset)
                } else {
                    ProgressView("Chargement de la page...")
                        .padding()
                }
                
                // Indicateurs de page précédente/suivante transparents sur les côtés
                HStack {
                    // Zone de tap pour page précédente (côté gauche)
                    Rectangle()
                        .opacity(0.001) // Pratiquement invisible
                        .frame(width: geometry.size.width / 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if currentPage > 1 {
                                currentPage -= 1
                                loadPage()
                            }
                        }
                    
                    Spacer()
                    
                    // Zone de tap pour page suivante (côté droit)
                    Rectangle()
                        .opacity(0.001) // Pratiquement invisible
                        .frame(width: geometry.size.width / 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if currentPage < book.pagesCount {
                                currentPage += 1
                                loadPage()
                            }
                        }
                }
                
                // Indicateur de chargement
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                        .padding(40)
                }
                
                // Indicateur de page en bas
                VStack {
                    Spacer()
                    Text("Page \(currentPage) / \(book.pagesCount)")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        // Déterminer si l'utilisateur a suffisamment glissé pour changer de page
                        let threshold = geometry.size.width * 0.2
                        
                        if value.translation.width > threshold {
                            // Swipe vers la droite (page précédente)
                            if currentPage > 1 {
                                currentPage -= 1
                                loadPage()
                            }
                        } else if value.translation.width < -threshold {
                            // Swipe vers la gauche (page suivante)
                            if currentPage < book.pagesCount {
                                currentPage += 1
                                loadPage()
                            }
                        }
                    }
            )
        }
        .ignoresSafeArea(.all, edges: .horizontal)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            leading: Text(book.name).font(.headline),
            trailing: Button(action: {
                // Option pour afficher les contrôles ou paramètres (facultatif)
            }) {
                Image(systemName: "gear")
            }
        )
        .onAppear {
            loadPage()
        }
        .statusBar(hidden: true) // Cache la barre d'état pour une meilleure immersion
    }
    
    private func loadPage() {
        isLoading = true
        pageImage = nil
        
        APIService().fetchPageImage(bookId: book.id, page: currentPage) { image in
            DispatchQueue.main.async {
                self.pageImage = image
                self.isLoading = false
            }
        }
    }
}
