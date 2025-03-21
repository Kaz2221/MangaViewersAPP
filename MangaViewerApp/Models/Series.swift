//
//  Series.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-03-18.
//

import Foundation

struct SeriesResponse: Codable {
    let content: [Series] // API returns series inside "content"
}

struct Series: Codable, Identifiable {
    let id: String
    let libraryId: String
    let name: String
    let booksCount: Int
}
