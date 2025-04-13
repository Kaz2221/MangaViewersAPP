// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Onglet Home - Votre ContentView existante
            ContentView()
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
                .tag(0)

            // Onglet Recherche
            SearchView()
                .tabItem {
                    Label("Recherche", systemImage: "magnifyingglass")
                }
                .tag(1)

            // Onglet Favoris - now using real FavoritesView
            FavoritesView(authService: authService)
                .tabItem {
                    Label("Favoris", systemImage: "heart")
                }
                .tag(2)

            // Onglet Profil - maintenant avec la vraie vue
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
                .tag(3)
        }
        .accentColor(.blue) // La couleur des icônes sélectionnées
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
