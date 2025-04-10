import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import Combine

// Modèle local pour stocker les données utilisateur depuis Firestore
struct UserProfile {
    var firstName: String
    var lastName: String
    var nickname: String
    var imageUrl: String
}

class AuthenticationService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    @Published var userProfile: UserProfile? // ✅ Infos Firestore

    private var cancellables = Set<AnyCancellable>()

    init() {
        FirebaseAuth.Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil

            if let user = user {
                self?.fetchUserProfile(uid: user.uid)
            } else {
                self?.userProfile = nil
            }
        }
    }

    func signUp(email: String, password: String) {
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }

            self?.isAuthenticated = true
        }
    }

    func signIn(email: String, password: String) {
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }

            self?.isAuthenticated = true
        }
    }

    func signOut() {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            isAuthenticated = false
            user = nil
            userProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ✅ Récupération des infos Firestore
    private func fetchUserProfile(uid: String) {
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { [weak self] document, error in
            if let error = error {
                print("Erreur récupération Firestore : \(error.localizedDescription)")
                return
            }

            guard let data = document?.data() else {
                print("Aucune donnée utilisateur trouvée.")
                return
            }

            let profile = UserProfile(
                firstName: data["firstName"] as? String ?? "",
                lastName: data["lastName"] as? String ?? "",
                nickname: data["nickname"] as? String ?? "",
                imageUrl: data["imageUrl"] as? String ?? ""
            )

            DispatchQueue.main.async {
                self?.userProfile = profile
            }
        }
    }

    // ✅ Suppression complète du compte utilisateur
    func deleteAccount(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur introuvable"]))
            return
        }

        let uid = user.uid
        let db = Firestore.firestore()
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")

        // Étape 1 : Supprimer l'image de profil si elle existe
        storageRef.delete { _ in
            // Ignore l’erreur si l’image n’existe pas

            // Étape 2 : Supprimer le document Firestore
            db.collection("users").document(uid).delete { error in
                if let error = error {
                    completion(error)
                    return
                }

                // Étape 3 : Supprimer le compte Auth
                user.delete { error in
                    if let error = error {
                        completion(error)
                    } else {
                        DispatchQueue.main.async {
                            self.isAuthenticated = false
                            self.user = nil
                            self.userProfile = nil
                        }
                        completion(nil)
                    }
                }
            }
        }
    }
}

