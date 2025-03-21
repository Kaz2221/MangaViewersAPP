import Foundation

// Modèles pour l'API Jikan
struct MangaListResponse: Decodable {
    let data: [MangaData]
}

struct MangaResponse: Decodable {
    let data: MangaData
}

struct MangaData: Decodable {
    let malId: Int
    let title: String
    let titleJapanese: String?
    let synopsis: String?
    let published: MangaPublished?
    let authors: [MangaAuthor]?
    let genres: [MangaGenre]?
    let score: Double?
    let images: MangaImages
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case title, synopsis, published, authors, genres, score, images, status
        case titleJapanese = "title_japanese"
    }
}

struct MangaImages: Decodable {
    let jpg: MangaImage
}

struct MangaImage: Decodable {
    let imageUrl: String
    let largeImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case largeImageUrl = "large_image_url"
    }
}

struct MangaPublished: Decodable {
    let from: String?
    let to: String?
    
    var formattedDateRange: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        
        var result = ""
        
        if let fromString = from, let fromDate = dateFormatter.date(from: fromString) {
            result = outputFormatter.string(from: fromDate)
        }
        
        if let toString = to, let toDate = dateFormatter.date(from: toString) {
            result += " - " + outputFormatter.string(from: toDate)
        }
        
        return result.isEmpty ? "Date inconnue" : result
    }
}

struct MangaAuthor: Decodable {
    let name: String
}

struct MangaGenre: Decodable {
    let name: String
}
