//
//  UserService.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-04-08.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

class UserService {
    static let shared = UserService()
    private init() {}

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // Méthode pour enregistrer un utilisateur (ajout de nickname)
    func saveUserData(
        uid: String,
        firstName: String,
        lastName: String,
        nickname: String,
        email: String,
        image: UIImage?,
        completion: @escaping (Error?) -> Void
    ) {
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.4) {
            let imageRef = storage.reference().child("profile_images/\(uid).jpg")
            print("Début de l'upload de l'image")

            let uploadTask = imageRef.putData(imageData, metadata: nil)

            uploadTask.observe(.success) { _ in
                print("Upload terminé, récupération de l'URL...")

                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Erreur lors de la récupération de l'URL : \(error.localizedDescription)")
                        completion(error)
                        return
                    }

                    guard let imageUrl = url?.absoluteString else {
                        let urlError = NSError(domain: "StorageURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image URL is nil"])
                        completion(urlError)
                        return
                    }

                    print("Image URL récupérée avec succès : \(imageUrl)")

                    self.saveUserDocument(
                        uid: uid,
                        firstName: firstName,
                        lastName: lastName,
                        nickname: nickname,
                        email: email,
                        imageUrl: imageUrl,
                        completion: completion
                    )
                }
            }

            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    print("Erreur pendant l'upload : \(error.localizedDescription)")
                    completion(error)
                }
            }
        } else {
            print("Aucune image sélectionnée, enregistrement des données sans image")
            self.saveUserDocument(
                uid: uid,
                firstName: firstName,
                lastName: lastName,
                nickname: nickname,
                email: email,
                imageUrl: "",
                completion: completion
            )
        }
    }

    // Méthode interne pour enregistrer les données Firestore (ajout de nickname)
    private func saveUserDocument(
        uid: String,
        firstName: String,
        lastName: String,
        nickname: String,
        email: String,
        imageUrl: String,
        completion: @escaping (Error?) -> Void
    ) {
        let data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "nickname": nickname,
            "email": email,
            "imageUrl": imageUrl
        ]

        db.collection("users").document(uid).setData(data) { error in
            if let error = error {
                print("Erreur lors de l'enregistrement Firestore : \(error.localizedDescription)")
            } else {
                print("Enregistrement Firestore réussi")
            }
            completion(error)
        }
    }
}

