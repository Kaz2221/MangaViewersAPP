//
//  BookListView.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-03-18.
//

import SwiftUI


struct BookListView: View {
    let series: Series
    @State private var books: [Book] = []
    
    var body: some View {
        VStack {
            if books.isEmpty {
                Text("Loading books...")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(books) { book in
                    NavigationLink(destination: ReaderView(book: book)) { // 🔹 Make book clickable
                        VStack(alignment: .leading) {
                            Text(book.name)
                                .font(.headline)
                            Text("Pages: \(book.pagesCount)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle(series.name)
        .onAppear {
            fetchBooks()
        }
    }
    
    private func fetchBooks() {
        APIService().fetchBooks(for: series.id) { fetchedBooks in
            if let fetchedBooks = fetchedBooks {
                DispatchQueue.main.async {
                    self.books = fetchedBooks
                }
            }
        }
    }
}
struct BookListView_Previews: PreviewProvider {
    static var previews: some View {
        BookListView(series: Series(id: "sample", libraryId: "lib1", name: "One Piece", booksCount: 5))
    }
}
