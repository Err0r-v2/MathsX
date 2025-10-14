//
//  CreateCardView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct CreateCardView: View {
    let deckId: UUID
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var front = ""
    @State private var back = ""
    @State private var isLatex = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                        
                        Spacer()
                        
                        Text("Nouvelle Carte")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button(action: createCard) {
                            Text("Créer")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(color: Theme.neon, verticalPadding: 8, horizontalPadding: 16))
                        .disabled(front.isEmpty || back.isEmpty)
                        .opacity(front.isEmpty || back.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            Toggle(isOn: $isLatex) {
                                HStack {
                                    Image(systemName: "function")
                                        .font(.body)
                                    Text("Format LaTeX")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.white)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
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
                            
                            VStack(alignment: .leading, spacing: 8) {
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
                            
                            if isLatex {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Exemples LaTeX:")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("• Fraction: \\frac{a}{b}")
                                        Text("• Puissance: x^{2}")
                                        Text("• Racine: \\sqrt{x}")
                                        Text("• Somme: \\sum_{i=1}^{n}")
                                        Text("• Intégrale: \\int_{a}^{b}")
                                    }
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.5))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Theme.neon.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.neon.opacity(0.15), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createCard() {
        let newCard = Flashcard(
            front: front,
            back: back,
            isLatex: isLatex
        )
        viewModel.addCard(to: deckId, card: newCard)
        dismiss()
    }
}
