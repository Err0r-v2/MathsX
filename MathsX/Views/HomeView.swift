//
//  HomeView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = DeckViewModel()
    @StateObject private var settingsManager = SettingsManager()
    @State private var showingCreateDeck = false
    @State private var showingCreateFolder = false
    @State private var showingSettings = false
    @State private var selectedDeck: Deck?
    @State private var selectedFolder: Folder?
    @State private var searchText: String = ""
    @State private var deckToDelete: Deck? = nil
    @State private var folderToDelete: Folder? = nil
    @State private var showingDeleteDeckAlert = false
    @State private var showingDeleteFolderAlert = false
    @State private var deckToMove: Deck? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        header
                        content
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateDeck) {
                CreateDeckView(viewModel: viewModel, settingsManager: settingsManager, folderId: nil)
            }
            .sheet(isPresented: $showingCreateFolder) {
                CreateFolderView(viewModel: viewModel, parentId: nil)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settingsManager: settingsManager)
            }
            .sheet(item: $selectedDeck) { deck in
                DeckDetailView(deck: deck, viewModel: viewModel, settingsManager: settingsManager)
            }
            .sheet(item: $selectedFolder) { folder in
                FolderView(folder: folder, viewModel: viewModel, settingsManager: settingsManager)
            }
            .sheet(item: $deckToMove) { deck in
                MoveDeckView(deck: deck, viewModel: viewModel)
            }
            .alert("Supprimer le deck ?", isPresented: $showingDeleteDeckAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    if let deck = deckToDelete {
                        viewModel.deleteDeck(deck)
                    }
                }
            } message: {
                Text("Cette action supprimera également toutes les cartes du deck.")
            }
            .alert("Supprimer le dossier ?", isPresented: $showingDeleteFolderAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    if let folder = folderToDelete {
                        viewModel.deleteFolder(folder)
                    }
                }
            } message: {
                Text("Le contenu du dossier sera déplacé à la racine.")
            }
        }
    }
    
    private var header: some View {
        HStack(spacing: 10) {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(GlowButtonStyle())

            // Inline search bar in header
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: 16))
                TextField("Rechercher...", text: $searchText)
                    .foregroundStyle(.white)
                    .tint(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Button(action: { showingCreateFolder = true }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(GlowButtonStyle())

                Button(action: { showingCreateDeck = true }) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(GlowButtonStyle())
            }
        }
    }
    
    private var filteredDecks: [Deck] {
        let rootDecks = viewModel.decks(in: nil)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return rootDecks
        } else {
            return rootDecks.filter { deck in
                deck.name.localizedCaseInsensitiveContains(searchText) ||
                deck.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredFolders: [Folder] {
        let rootFolders = viewModel.folders(in: nil)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return rootFolders
        } else {
            return rootFolders.filter { folder in
                folder.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var content: some View {
        ScrollView(showsIndicators: false) {
            // Stats row
            HStack(spacing: 12) {
                StatCard(
                    title: "Dossiers",
                    value: "\(viewModel.folders.count)",
                    icon: "folder.fill"
                )
                
                StatCard(
                    title: "Decks",
                    value: "\(viewModel.decks.count)",
                    icon: "square.stack.3d.up.fill"
                )
            }
            .padding(.bottom, 6)
            
            // Folders and Decks grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                // Folders
                ForEach(filteredFolders) { folder in
                    Button(action: { selectedFolder = folder }) {
                        FolderCard(folder: folder, viewModel: viewModel, onDelete: {
                            folderToDelete = folder
                            showingDeleteFolderAlert = true
                        })
                    }
                    .buttonStyle(.plain)
                }
                
                // Decks
                ForEach(filteredDecks) { deck in
                    Button(action: { selectedDeck = deck }) {
                        DeckCard(deck: deck, viewModel: viewModel, onDelete: {
                            deckToDelete = deck
                            showingDeleteDeckAlert = true
                        }, onMove: {
                            deckToMove = deck
                        })
                    }
                    .buttonStyle(.plain)
                }
                
                // Add new deck button
                Button(action: { showingCreateDeck = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("Nouveau Deck")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                            )
                            .foregroundStyle(Color.white.opacity(0.2))
                    )
                }
                
                // Add new folder button
                Button(action: { showingCreateFolder = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("Nouveau Dossier")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                            )
                            .foregroundStyle(Color.white.opacity(0.2))
                    )
                }
            }
            // Bottom spacer
            Color.clear.frame(height: 40)
        }
    }
    
    
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 14) {
            // Icône
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(Theme.neon)
                .neonGlow(Theme.neon, radius: 12)
                .frame(width: 40, height: 40)
            
            // Nombre et label
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 68)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct DeckCard: View {
    let deck: Deck
    @ObservedObject var viewModel: DeckViewModel
    let onDelete: () -> Void
    var onMove: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "function")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.neon)
                    .neonGlow(Theme.neon, radius: 8)
                
                Spacer()
                
                Text("\(deck.cards.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(deck.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text(deck.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .contextMenu {
            if let onMove = onMove {
                Button {
                    onMove()
                } label: {
                    Label("Déplacer", systemImage: "folder.badge.gear")
                }
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Supprimer le deck", systemImage: "trash")
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HomeView()
}
