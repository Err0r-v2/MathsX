//
//  EditDeckView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct EditDeckView: View {
    let deckId: UUID
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateCard = false
    @State private var cardToDelete: Flashcard? = nil
    @State private var showingDeleteAlert = false
    @State private var cardToEdit: Flashcard? = nil
    
    private var deck: Deck? {
        viewModel.decks.first(where: { $0.id == deckId })
    }
    
    var body: some View {
        Group {
            if let currentDeck = deck {
                editDeckContent(for: currentDeck)
            } else {
                Text("Deck non trouvé")
                    .foregroundStyle(.white)
            }
        }
    }
    
    private func editDeckContent(for currentDeck: Deck) -> some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                    
                    Spacer()
                    
                    Text("Modifier le Deck")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Add card button
                        Button(action: { showingCreateCard = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Theme.neon)
                                
                                Text("Ajouter une Carte")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Theme.neon.opacity(0.3), lineWidth: 1.5)
                            )
                        }
                        
                        // Cards list
                        if !currentDeck.cards.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("\(currentDeck.cards.count) cartes")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                ForEach(currentDeck.cards) { card in
                                    EditableCardRow(card: card, onEdit: {
                                        cardToEdit = card
                                    }, onDelete: {
                                        cardToDelete = card
                                        showingDeleteAlert = true
                                    })
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "tray")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.3))
                                
                                Text("Aucune carte")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Text("Ajoutez des cartes pour commencer")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateCard) {
            CreateCardView(deckId: currentDeck.id, viewModel: viewModel)
        }
        .sheet(item: $cardToEdit) { card in
            EditCardView(deckId: currentDeck.id, card: card, viewModel: viewModel)
        }
        .alert("Supprimer la carte ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                if let card = cardToDelete {
                    viewModel.deleteCard(card, from: currentDeck)
                }
            }
        } message: {
            Text("Cette action est irréversible.")
        }
    }
}

struct EditableCardRow: View {
    let card: Flashcard
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var dragOffsetX: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Card content (tappable)
            VStack(alignment: .leading, spacing: 8) {
                if card.isLatex {
                    CachedSwiftMathView(latex: card.front, fontSize: 14, textColor: .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 50)
                        .clipped()
                } else {
                    Text(card.front)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                if card.isLatex {
                    CachedSwiftMathView(latex: card.back, fontSize: 12, textColor: .white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 40)
                        .clipped()
                } else {
                    Text(card.back)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }
        }
        .padding(14)
        .frame(minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                // Icône poubelle qui apparaît visuellement lors du swipe gauche
                Image(systemName: "trash.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .opacity(max(0, min(1, (-dragOffsetX) / 80)))
                    .padding(.trailing, 16)
            }
        )
        .overlay(alignment: .leading) {
            // Overlay transparent cliquable (pleine largeur)
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .contentShape(Rectangle())
                .onTapGesture { onEdit() }
        }
        .offset(x: dragOffsetX)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Ne considérer que le swipe gauche
                    dragOffsetX = min(0, value.translation.width)
                }
                .onEnded { value in
                    let shouldDelete = value.translation.width < -80
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffsetX = 0
                    }
                    if shouldDelete {
                        onDelete()
                    }
                }
        )
    }
}

