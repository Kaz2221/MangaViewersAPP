//
//  FavoritesService.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-04-11.
//
import Foundation
import Firebase
import FirebaseFirestore
import Combine

class FavoritesService: ObservableObject {
    @Published var favorites: [Favorite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    deinit {
        // Detach listener when service is deallocated
        removeListener()
    }
    
    // Start listening to favorites for a specific user
    func startListening(forUserId userId: String) {
        // Clean up any existing listener
        removeListener()
        isLoading = true
        
        // Listen to favorites collection, filtered by userId
        let query = db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .order(by: "dateAdded", descending: true)
        
        listenerRegistration = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                // Check if this is a network reconnection error - these are normal when reopening the app
                if error.localizedDescription.contains("network") ||
                   error.localizedDescription.contains("connection") {
                    // Just log it, don't show to user since favorites will still load from cache
                    print("Firestore reconnecting: \(error.localizedDescription)")
                } else {
                    // Only show error message for non-network related issues
                    self.errorMessage = "Error fetching favorites: \(error.localizedDescription)"
                }
                return
            }
            
            guard let documents = snapshot?.documents else {
                // Don't show error for empty favorites, just return empty array
                self.favorites = []
                return
            }
            
            // Parse documents into Favorite objects
            self.favorites = documents.compactMap { document -> Favorite? in
                let data = document.data()
                
                guard let userId = data["userId"] as? String,
                      let seriesId = data["seriesId"] as? String,
                      let seriesName = data["seriesName"] as? String,
                      let timestamp = data["dateAdded"] as? Timestamp else {
                    return nil
                }
                
                return Favorite(
                    id: document.documentID,
                    userId: userId,
                    seriesId: seriesId,
                    seriesName: seriesName,
                    coverUrl: data["coverUrl"] as? String,
                    dateAdded: timestamp.dateValue()
                )
            }
        }
    }
    
    // Remove listener when user logs out
    func removeListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    // Add a manga series to favorites
    func addFavorite(series: Series, userId: String, completion: @escaping (Error?) -> Void) {
        // Check if already favorited
        if favorites.contains(where: { $0.seriesId == series.id }) {
            completion(nil) // Already a favorite
            return
        }
        
        // Create favorite object
        let favorite = Favorite.fromSeries(series: series, userId: userId)
        
        // Add to Firestore
        db.collection("favorites").document(favorite.id).setData(favorite.dictionary) { error in
            if let error = error {
                self.errorMessage = "Failed to add favorite: \(error.localizedDescription)"
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Remove a manga series from favorites
    func removeFavorite(seriesId: String, completion: @escaping (Error?) -> Void) {
        // Find the favorite document to remove
        guard let favorite = favorites.first(where: { $0.seriesId == seriesId }) else {
            completion(nil) // Not a favorite
            return
        }
        
        // Remove from Firestore
        db.collection("favorites").document(favorite.id).delete { error in
            if let error = error {
                self.errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Check if a series is in favorites
    func isFavorite(seriesId: String) -> Bool {
        return favorites.contains(where: { $0.seriesId == seriesId })
    }
}
