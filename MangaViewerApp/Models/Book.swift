//
//  Book.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-03-18.
//

import Foundation

struct BookResponse: Codable {
    let content: [Book] // API returns books inside "content"
}

struct Media: Codable {
    let pagesCount: Int
}

struct Book: Codable, Identifiable {
    let id: String
    let seriesId: String
    let seriesTitle: String
    let libraryId: String
    let name: String
    let number: Int
    let size: String
    let media: Media // Nested media object

    var pagesCount: Int {
        return media.pagesCount
    }
}
