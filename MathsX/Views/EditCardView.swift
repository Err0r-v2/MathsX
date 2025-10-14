//
//  EditCardView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct EditCardView: View {
    let deckId: UUID
    let card: Flashcard
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var front: String
    @State private var back: String
    @State private var isLatex: Bool
    
    init(deckId: UUID, card: Flashcard, viewModel: DeckViewModel) {
        self.deckId = deckId
        self.card = card
        self.viewModel = viewModel
        _front = State(initialValue: card.front)
        _back = State(initialValue: card.back)
        _isLatex = State(initialValue: card.isLatex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // LaTeX toggle
                        Toggle(isOn: $isLatex) {
                            HStack {
                                Image(systemName: "function")
                                    .foregroundStyle(Theme.neon)
                                Text("Carte LaTeX")
                                    .foregroundStyle(.white)
                            }
                        }
                        .tint(Theme.neon)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        
                        // Front
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recto (Question)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            TextEditor(text: $front)
                                .font(.system(size: 16, design: isLatex ? .monospaced : .default))
                                .foregroundStyle(.white)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            
                            if isLatex && !front.isEmpty {
                                Text("Aperçu:")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                CachedSwiftMathView(latex: front, fontSize: 18, textColor: .white, debounce: true)
                                    .frame(height: 70)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.03))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Back
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Verso (Réponse)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            TextEditor(text: $back)
                                .font(.system(size: 16, design: isLatex ? .monospaced : .default))
                                .foregroundStyle(.white)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            
                            if isLatex && !back.isEmpty {
                                Text("Aperçu:")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                CachedSwiftMathView(latex: back, fontSize: 18, textColor: .white, debounce: true)
                                    .frame(height: 70)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.03))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Save button
                        Button(action: saveCard) {
                            Text("Enregistrer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlowButtonStyle(color: Theme.neon, verticalPadding: 14, horizontalPadding: 24))
                        .disabled(front.isEmpty || back.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Modifier la Carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func saveCard() {
        let updatedCard = Flashcard(
            id: card.id,
            front: front,
            back: back,
            isLatex: isLatex
        )
        viewModel.updateCard(in: deckId, card: updatedCard)
        dismiss()
    }
}

