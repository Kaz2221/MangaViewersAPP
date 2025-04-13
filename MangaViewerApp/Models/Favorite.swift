//
//  Favorite.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-04-11.
//
import Foundation
import FirebaseFirestore

struct Favorite: Identifiable, Codable {
    var id: String = UUID().uuidString
    let userId: String
    let seriesId: String
    let seriesName: String
    let coverUrl: String?
    let dateAdded: Date
    
    // For Firestore serialization
    var dictionary: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "seriesId": seriesId,
            "seriesName": seriesName,
            "coverUrl": coverUrl ?? "",
            "dateAdded": Timestamp(date: dateAdded)
        ]
    }
    
    // Create a Favorite from a Series
    static func fromSeries(series: Series, userId: String) -> Favorite {
        return Favorite(
            userId: userId,
            seriesId: series.id,
            seriesName: series.name,
            coverUrl: nil,
            dateAdded: Date()
        )
    }
}
