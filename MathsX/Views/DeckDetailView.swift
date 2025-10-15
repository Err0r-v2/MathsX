//
//  DeckDetailView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct DeckDetailView: View {
    let deck: Deck
    @ObservedObject var viewModel: DeckViewModel
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingFlashcards = false
    @State private var showingQuiz = false
    @State private var showingEditDeck = false
    @State private var showingDeleteDeckAlert = false
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Deck info
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "function")
                                        .font(.system(size: 32))
                                        .foregroundStyle(Theme.neon)
                                        .neonGlow(Theme.neon)
                                    
                                    Spacer()
                                    Menu {
                                        Button {
                                            showingEditDeck = true
                                        } label: {
                                            Label("Modifier le deck", systemImage: "pencil")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            showingDeleteDeckAlert = true
                                        } label: {
                                            Label("Supprimer le deck", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.title3)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                
                                Text(deck.name)
                                    .font(.title.bold())
                                    .foregroundStyle(.white)
                                
                                if !deck.description.isEmpty {
                                    Text(deck.description)
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                
                                Text("\(deck.cards.count) cartes")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 14) {
                            ActionButton(
                                title: "Mode Révision",
                                icon: "rectangle.on.rectangle.angled",
                                action: { showingFlashcards = true }
                            )
                            .disabled(deck.cards.isEmpty)
                            .opacity(deck.cards.isEmpty ? 0.5 : 1)
                            
                            ActionButton(
                                title: "Mode Quiz",
                                icon: "questionmark.circle.fill",
                                action: { showingQuiz = true }
                            )
                            .disabled(deck.cards.count < 4)
                            .opacity(deck.cards.count < 4 ? 0.5 : 1)
                            
                            // Bouton "Modifier le Deck" déplacé dans le menu (ellipsis)
                        }
                        
                        // Cards list
                        if !deck.cards.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Cartes")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                ForEach(deck.cards) { card in
                                    GlassCard {
                                        CardPreview(card: card)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingFlashcards) {
            FlashcardView(deck: deck, viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingQuiz) {
            QuizView(deck: deck, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditDeck) {
            EditDeckView(deckId: deck.id, viewModel: viewModel, settingsManager: settingsManager)
        }
        .alert("Supprimer ce deck ?", isPresented: $showingDeleteDeckAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                viewModel.deleteDeck(deck)
                dismiss()
            }
        } message: {
            Text("Cette action supprimera définitivement ce deck et toutes ses cartes.")
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

struct CardPreview: View {
    let card: Flashcard
    
    var body: some View {
        VStack(spacing: 12) {
            if card.isLatex {
                CachedSwiftMathView(latex: card.front, fontSize: 16, textColor: .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .clipped()
            } else {
                Text(card.front)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            if card.isLatex {
                CachedSwiftMathView(latex: card.back, fontSize: 14, textColor: .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .clipped()
            } else {
                Text(card.back)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
