//
//  APIService.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-03-18.
//
import UIKit
import Foundation
import Combine

class APIService: ObservableObject {
    // Primary and fallback server URLs
    private let localBaseURL = "http://localhost:25600/api/v1"
    private let remoteBaseURL = "https://your-remote-api.com/api/v1" // Replace with your actual remote API if available
    
    // Server connection state
    @Published var isServerAvailable = false
    @Published var serverMessage: String = "Checking server availability..."
    
    // Track which URL is currently active
    var activeBaseURL: String
    private var isUsingFallback = false
    
    private let username = "maxmiramora@gmail.com"
    private let password = "max123"
    
    // Default timeout interval for requests
    private let timeoutInterval: TimeInterval = 10.0

    public var authHeader: String {
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else { return "" }
        return "Basic \(data.base64EncodedString())"
    }
    
    // MARK: - Initialization
    
    init() {
        self.activeBaseURL = localBaseURL
        checkServerAvailability()
    }
    
    // MARK: - Server Availability
    
    func checkServerAvailability() {
        guard let url = URL(string: "\(localBaseURL)/series") else {
            self.isServerAvailable = false
            self.serverMessage = "Invalid server URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5.0 // Short timeout for checking availability
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Server connectivity error: \(error.localizedDescription)")
                    self.isServerAvailable = false
                    self.serverMessage = "Server unavailable: \(error.localizedDescription)"
                    self.switchToFallbackIfNeeded()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    let isSuccess = (200...299).contains(httpResponse.statusCode)
                    self.isServerAvailable = isSuccess
                    
                    if isSuccess {
                        self.serverMessage = "Server is available"
                        self.activeBaseURL = self.localBaseURL
                        self.isUsingFallback = false
                    } else {
                        self.serverMessage = "Server returned error: \(httpResponse.statusCode)"
                        self.switchToFallbackIfNeeded()
                    }
                } else {
                    self.isServerAvailable = false
                    self.serverMessage = "Invalid server response"
                    self.switchToFallbackIfNeeded()
                }
            }
        }
        task.resume()
    }
    
    private func switchToFallbackIfNeeded() {
        if !isUsingFallback {
            isUsingFallback = true
            activeBaseURL = remoteBaseURL
            print("⚠️ Switched to fallback server: \(remoteBaseURL)")
        }
    }
    
    // MARK: - Mock Data
    
    // Generate mock data when server is unavailable
    private func getMockSeries() -> [Series] {
        return [
            Series(id: "mock1", libraryId: "lib1", name: "One Piece", booksCount: 1084),
            Series(id: "mock2", libraryId: "lib1", name: "Naruto", booksCount: 700),
            Series(id: "mock3", libraryId: "lib1", name: "Dragon Ball", booksCount: 520),
            Series(id: "mock4", libraryId: "lib1", name: "Attack on Titan", booksCount: 139),
            Series(id: "mock5", libraryId: "lib1", name: "My Hero Academia", booksCount: 362),
            Series(id: "mock6", libraryId: "lib1", name: "Demon Slayer", booksCount: 205)
        ]
    }
    
    private func getMockBooks(for seriesId: String) -> [Book] {
        // Create dynamic book names based on series ID
        var seriesName = "Unknown Series"
        
        if seriesId == "mock1" { seriesName = "One Piece" }
        else if seriesId == "mock2" { seriesName = "Naruto" }
        else if seriesId == "mock3" { seriesName = "Dragon Ball" }
        else if seriesId == "mock4" { seriesName = "Attack on Titan" }
        else if seriesId == "mock5" { seriesName = "My Hero Academia" }
        else if seriesId == "mock6" { seriesName = "Demon Slayer" }
        
        var mockBooks: [Book] = []
        
        // Generate 5 mock books for this series
        for i in 1...5 {
            let mockMedia = Media(pagesCount: 45)
            mockBooks.append(
                Book(
                    id: "book_\(seriesId)_\(i)",
                    seriesId: seriesId,
                    seriesTitle: seriesName,
                    libraryId: "lib1",
                    name: "Volume \(i)",
                    number: i,
                    size: "25MB",
                    media: mockMedia
                )
            )
        }
        
        return mockBooks
    }
    
    // MARK: - API Methods

    func fetchSeries(completion: @escaping ([Series]?) -> Void) {
        guard let url = URL(string: "\(activeBaseURL)/series") else {
            print("Invalid URL")
            // Return mock data if URL is invalid
            DispatchQueue.main.async {
                completion(self.getMockSeries())
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeoutInterval

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        print("Request timed out")
                    case .cannotConnectToHost, .networkConnectionLost:
                        print("Connection issues. Server might be down.")
                        self.checkServerAvailability()
                    default:
                        print("URL Error: \(urlError.code.rawValue)")
                    }
                }
                
                // Return mock data on error
                DispatchQueue.main.async {
                    completion(self.getMockSeries())
                }
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(self.getMockSeries())
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(self.getMockSeries())
                }
                return
            }
            
            // Print first 200 chars of response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = String(responseString.prefix(200))
                print("API Response preview: \(preview)...")
            }

            do {
                // Try to decode the response with content wrapper
                let response = try JSONDecoder().decode(SeriesResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.content)
                }
            } catch {
                print("Decoding error: \(error)")
                
                // Try alternative decoding (direct array)
                do {
                    let series = try JSONDecoder().decode([Series].self, from: data)
                    DispatchQueue.main.async {
                        completion(series)
                    }
                } catch {
                    print("Alternative decoding also failed: \(error)")
                    DispatchQueue.main.async {
                        completion(self.getMockSeries())
                    }
                }
            }
        }
        task.resume()
    }
    
    func fetchSeriesCover(seriesId: String, completion: @escaping (UIImage?) -> Void) {
        // For mock series, return a colored placeholder
        if seriesId.starts(with: "mock") {
            DispatchQueue.main.async {
                let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemRed, .systemTeal]
                let colorIndex = Int(seriesId.dropFirst(4)) ?? 0
                let color = colors[colorIndex % colors.count]
                
                // Create a colored placeholder image
                let size = CGSize(width: 300, height: 450)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                color.setFill()
                UIRectFill(CGRect(origin: .zero, size: size))
                
                // Add text to the image
                let text = seriesId.starts(with: "mock1") ? "One Piece" :
                           seriesId.starts(with: "mock2") ? "Naruto" :
                           seriesId.starts(with: "mock3") ? "Dragon Ball" :
                           seriesId.starts(with: "mock4") ? "Attack on Titan" :
                           seriesId.starts(with: "mock5") ? "My Hero Academia" :
                           seriesId.starts(with: "mock6") ? "Demon Slayer" : "Manga"
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.white
                ]
                
                let textSize = text.size(withAttributes: attributes)
                let rect = CGRect(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
                text.draw(in: rect, withAttributes: attributes)
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                completion(image)
            }
            return
        }
        
        let urlString = "\(activeBaseURL)/series/\(seriesId)/thumbnail"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeoutInterval

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Cover fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data received")
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    func fetchPageImage(bookId: String, page: Int, completion: @escaping (UIImage?) -> Void) {
        // For mock books, return a colored placeholder
        if bookId.starts(with: "book_mock") {
            DispatchQueue.main.async {
                // Create a placeholder page
                let size = CGSize(width: 800, height: 1200)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                UIColor.lightGray.setFill()
                UIRectFill(CGRect(origin: .zero, size: size))
                
                // Add page number to the image
                let text = "Page \(page)"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 36),
                    .foregroundColor: UIColor.black
                ]
                
                let textSize = text.size(withAttributes: attributes)
                let rect = CGRect(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
                text.draw(in: rect, withAttributes: attributes)
                
                // Extract series info from the bookId format "book_mockX_Y"
                let components = bookId.split(separator: "_")
                if components.count >= 2 {
                    let seriesText: String
                    if components[1] == "mock1" { seriesText = "One Piece" }
                    else if components[1] == "mock2" { seriesText = "Naruto" }
                    else if components[1] == "mock3" { seriesText = "Dragon Ball" }
                    else if components[1] == "mock4" { seriesText = "Attack on Titan" }
                    else if components[1] == "mock5" { seriesText = "My Hero Academia" }
                    else if components[1] == "mock6" { seriesText = "Demon Slayer" }
                    else { seriesText = "Manga" }
                    
                    let volumeText = "Volume \(components.last ?? "")"
                    
                    // Draw series name at top
                    let titleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 24),
                        .foregroundColor: UIColor.black
                    ]
                    let titleRect = CGRect(x: 20, y: 30, width: size.width - 40, height: 30)
                    seriesText.draw(in: titleRect, withAttributes: titleAttributes)
                    
                    // Draw volume below
                    let volumeRect = CGRect(x: 20, y: 60, width: size.width - 40, height: 30)
                    volumeText.draw(in: volumeRect, withAttributes: [
                        .font: UIFont.systemFont(ofSize: 18),
                        .foregroundColor: UIColor.darkGray
                    ])
                }
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                completion(image)
            }
            return
        }
        
        let urlString = "\(activeBaseURL)/books/\(bookId)/pages/\(page)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeoutInterval

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Page fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data received for page \(page)")
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

    func fetchBooks(for seriesId: String, completion: @escaping ([Book]?) -> Void) {
        // For mock series, return mock books
        if seriesId.starts(with: "mock") {
            DispatchQueue.main.async {
                completion(self.getMockBooks(for: seriesId))
            }
            return
        }
        
        guard let url = URL(string: "\(activeBaseURL)/series/\(seriesId)/books") else {
            print("Invalid URL for fetching books")
            DispatchQueue.main.async {
                completion(self.getMockBooks(for: seriesId))
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeoutInterval

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Books fetch error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(self.getMockBooks(for: seriesId))
                }
                return
            }

            guard let data = data else {
                print("No book data received")
                DispatchQueue.main.async {
                    completion(self.getMockBooks(for: seriesId))
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(BookResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.content)
                }
            } catch {
                print("Book decoding error: \(error)")
                
                // Try direct array decoding as fallback
                do {
                    let books = try JSONDecoder().decode([Book].self, from: data)
                    DispatchQueue.main.async {
                        completion(books)
                    }
                } catch {
                    print("Alternative book decoding also failed: \(error)")
                    DispatchQueue.main.async {
                        completion(self.getMockBooks(for: seriesId))
                    }
                }
            }
        }.resume()
    }
}
