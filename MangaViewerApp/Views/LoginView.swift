//
//  LoginView.swift
//  MangaViewerApp
//
//  Created by Maximiliano Miranda Mora on 2025-04-08.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // En-tête
            Text("Connexion")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Spacer()
            
            // Champs de saisie
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            SecureField("Mot de passe", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Bouton de connexion
            Button(action: {
                if !email.isEmpty && !password.isEmpty {
                    authService.signIn(email: email, password: password)
                    
                    // Si l'authentification réussit, revenir à la vue précédente
                    if authService.isAuthenticated {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                Text("Se connecter")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(email.isEmpty || password.isEmpty)
            
            Spacer()
            
            // Lien vers l'inscription
            Button(action: {
                isShowingSignUp = true
            }) {
                Text("Pas encore de compte ? S'inscrire")
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Connexion")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView(authService: authService)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authService: AuthenticationService())
    }
}
