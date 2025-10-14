//
//  MoveDeckView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import SwiftUI

struct MoveDeckView: View {
    let deck: Deck
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                        
                        Spacer()
                        
                        Text("Déplacer le deck")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Current deck info
                            HStack(spacing: 12) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Theme.neon)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(deck.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("\(deck.cards.count) carte(s)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            
                            // Root option
                            Button(action: {
                                viewModel.moveDeck(deck, to: nil)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .frame(width: 32)
                                    
                                    Text("Racine")
                                        .font(.body)
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    if deck.folderId == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.neon)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(deck.folderId == nil ? Theme.neon.opacity(0.1) : Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            deck.folderId == nil ? Theme.neon.opacity(0.3) : Color.white.opacity(0.15),
                                            lineWidth: 1
                                        )
                                )
                            }
                            
                            // Folders
                            if !viewModel.folders.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Dossiers")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .padding(.horizontal, 4)
                                    
                                    ForEach(allFolders) { folder in
                                        Button(action: {
                                            viewModel.moveDeck(deck, to: folder.id)
                                            dismiss()
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: folder.icon)
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(colorFromString(folder.color))
                                                    .frame(width: 32)
                                                
                                                Text(folder.name)
                                                    .font(.body)
                                                    .foregroundStyle(.white)
                                                
                                                Spacer()
                                                
                                                if deck.folderId == folder.id {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(Theme.neon)
                                                }
                                            }
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(deck.folderId == folder.id ? Theme.neon.opacity(0.1) : Color.white.opacity(0.06))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(
                                                        deck.folderId == folder.id ? Theme.neon.opacity(0.3) : Color.white.opacity(0.15),
                                                        lineWidth: 1
                                                    )
                                            )
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "folder.badge.questionmark")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.3))
                                    
                                    Text("Aucun dossier")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var allFolders: [Folder] {
        // Get all folders in a flat list (could be enhanced to show hierarchy)
        return viewModel.folders.sorted { $0.name < $1.name }
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

