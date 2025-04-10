//
//  ProfileView.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-04-08.
//

import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var showDeleteConfirmation = false // ✅ Confirmation alerte

    var body: some View {
        NavigationView {
            VStack {
                if authService.isAuthenticated {
                    authenticatedView
                } else {
                    unauthenticatedView
                }
            }
            .navigationTitle("Profil")
            .alert(isPresented: .constant(!authService.errorMessage.isEmpty)) {
                Alert(
                    title: Text("Erreur"),
                    message: Text(authService.errorMessage),
                    dismissButton: .default(Text("OK")) {
                        authService.errorMessage = ""
                    }
                )
            }
            .alert("Confirmer la suppression", isPresented: $showDeleteConfirmation, actions: {
                Button("Supprimer", role: .destructive) {
                    authService.deleteAccount { error in
                        if let error = error {
                            authService.errorMessage = error.localizedDescription
                        }
                    }
                }
                Button("Annuler", role: .cancel) {}
            }, message: {
                Text("Cette action est irréversible. Toutes vos données seront supprimées.")
            })
        }
    }

    // MARK: - Authenticated View
    private var authenticatedView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let imageUrl = authService.userProfile?.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        .shadow(radius: 4)
                        .padding(.top, 30)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.blue)
                        .padding(.top, 30)
                }

                VStack(spacing: 15) {
                    infoRow(title: "Email", value: authService.user?.email ?? "")
                    Divider()
                    infoRow(title: "Pseudo", value: authService.userProfile?.nickname ?? "Non défini")
                    Divider()
                    infoRow(title: "Nom", value: authService.userProfile?.lastName ?? "Non défini")
                    Divider()
                    infoRow(title: "Prénom", value: authService.userProfile?.firstName ?? "Non défini")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                if let profile = authService.userProfile {
                    NavigationLink(
                        destination: EditProfileView(
                            firstName: .constant(profile.firstName),
                            lastName: .constant(profile.lastName),
                            imageUrl: .constant(profile.imageUrl),
                            nickname: .constant(profile.nickname)
                        )
                    ) {
                        Text("Modifier le profil")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    authService.signOut()
                }) {
                    Text("Se déconnecter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Supprimer mon compte")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Unauthenticated View
    private var unauthenticatedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)

            Text("Vous n'êtes pas connecté")
                .font(.headline)

            Text("Connectez-vous pour accéder à votre profil")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            NavigationLink(destination: LoginView(authService: authService)) {
                Text("Se connecter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Info Row
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

