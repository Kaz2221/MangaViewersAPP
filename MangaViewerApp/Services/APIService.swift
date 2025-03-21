//
//  APIService.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-03-18.
//
import UIKit
import Foundation

class APIService {
    public let baseURL = "http://localhost:25600/api/v1"
    private let username = "djibril.m21@gmail.com"
    private let password = "djibril21"

    public var authHeader: String {
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else { return "" }
        return "Basic \(data.base64EncodedString())"
    }

    func fetchSeries(completion: @escaping ([Series]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/series") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Vérifiez le code de statut HTTP
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            // Imprimez la réponse brute
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(responseString)")
            }

            do {
                // Essayez de décoder la réponse
                let response = try JSONDecoder().decode(SeriesResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.content)
                }
            } catch {
                print("Decoding error: \(error)")
                
                // Tentez de décoder directement un tableau de Series (sans le wrapper "content")
                do {
                    let series = try JSONDecoder().decode([Series].self, from: data)
                    DispatchQueue.main.async {
                        completion(series)
                    }
                } catch {
                    print("Alternative decoding also failed: \(error)")
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func fetchSeriesCover(seriesId: String, completion: @escaping (UIImage?) -> Void) {
        let urlString = "\(baseURL)/series/\(seriesId)/thumbnail"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    func fetchPageImage(bookId: String, page: Int, completion: @escaping (UIImage?) -> Void) {
        let urlString = "\(baseURL)/books/\(bookId)/pages/\(page)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

    func fetchBooks(for seriesId: String, completion: @escaping ([Book]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/series/\(seriesId)/books") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("API request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            do {
                // Decode the full response first, then extract "content"
                let response = try JSONDecoder().decode(BookResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.content) // Extract books list from "content"
                }
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
