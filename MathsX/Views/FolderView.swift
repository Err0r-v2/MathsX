//
//  FolderView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import SwiftUI

struct FolderView: View {
    let folder: Folder
    @ObservedObject var viewModel: DeckViewModel
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCreateDeck = false
    @State private var showingCreateFolder = false
    @State private var selectedDeck: Deck?
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var deckToDelete: Deck? = nil
    @State private var folderToDelete: Folder? = nil
    @State private var showingDeleteDeckAlert = false
    @State private var showingDeleteFolderAlert = false
    @State private var selectedFolder: Folder? = nil
    @State private var deckToMove: Deck? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    header
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, isSearching ? 8 : 20)
            }

            // Overlay search bar centered at bottom
            searchBar
                .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateDeck) {
            CreateDeckView(viewModel: viewModel, settingsManager: settingsManager, folderId: folder.id)
        }
        .sheet(isPresented: $showingCreateFolder) {
            CreateFolderView(viewModel: viewModel, parentId: folder.id)
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
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                
                Spacer()
                
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
            
            HStack(spacing: 12) {
                Image(systemName: folder.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(colorFromString(folder.color))
                    .neonGlow(colorFromString(folder.color), radius: 12)
                
                Text(folder.name)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .neonGlow()
                
                Spacer()
            }
        }
    }
    
    private var filteredDecks: [Deck] {
        let decksInFolder = viewModel.decks(in: folder.id)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return decksInFolder
        } else {
            return decksInFolder.filter { deck in
                deck.name.localizedCaseInsensitiveContains(searchText) ||
                deck.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredFolders: [Folder] {
        let foldersInFolder = viewModel.folders(in: folder.id)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return foldersInFolder
        } else {
            return foldersInFolder.filter { folder in
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
                    value: "\(viewModel.folders(in: folder.id).count)",
                    icon: "folder.fill"
                )
                
                StatCard(
                    title: "Decks",
                    value: "\(viewModel.decks(in: folder.id).count)",
                    icon: "square.stack.3d.up.fill"
                )
            }
            .padding(.bottom, 6)
            
            // Folders and Decks grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                // Folders
                ForEach(filteredFolders) { subFolder in
                    Button(action: { selectedFolder = subFolder }) {
                        FolderCard(folder: subFolder, viewModel: viewModel, onDelete: {
                            folderToDelete = subFolder
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
            // Extra bottom spacer
            Color.clear.frame(height: isSearching ? 120 : 100)
        }
    }
    
    private var searchBar: some View {
        VStack(spacing: 0) {
            if isSearching {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 16))
                        
                        TextField("Rechercher...", text: $searchText)
                            .foregroundStyle(.white)
                            .tint(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    Button("Annuler") {
                        isSearching = false
                        searchText = ""
                        hideKeyboard()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.system(size: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSearching = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                            Text("Rechercher")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 16)
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
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isSearching)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func colorFromString(_ string: String) -> Color {
        switch string {
        case "cyan": return .cyan
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "yellow": return .yellow
        case "red": return .red
        default: return .cyan
        }
    }
}

struct FolderCard: View {
    let folder: Folder
    @ObservedObject var viewModel: DeckViewModel
    let onDelete: () -> Void
    
    private var totalCards: Int {
        viewModel.decks(in: folder.id).reduce(0) { $0 + $1.cards.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: folder.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(colorFromString(folder.color))
                    .neonGlow(colorFromString(folder.color), radius: 8)
                
                Spacer()
                
                Text("\(totalCards)")
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
                Text(folder.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text("\(viewModel.decks(in: folder.id).count) deck(s)")
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
                .fill(colorFromString(folder.color).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [colorFromString(folder.color).opacity(0.3), colorFromString(folder.color).opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Supprimer le dossier", systemImage: "trash")
            }
        }
    }
    
    private func colorFromString(_ string: String) -> Color {
        switch string {
        case "cyan": return .cyan
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "yellow": return .yellow
        case "red": return .red
        default: return .cyan
        }
    }
}

