// MainTabView.swift
import SwiftUI

struct MainTabView: View {
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
            
            // Onglet Favoris
            Text("Favoris - À implémenter")
                .tabItem {
                    Label("Favoris", systemImage: "heart")
                }
                .tag(2)
            
            // Onglet Profil
            Text("Profil - À implémenter")
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
                .tag(3)
        }
        .accentColor(.blue) // La couleur des icônes sélectionnées
    }
}
