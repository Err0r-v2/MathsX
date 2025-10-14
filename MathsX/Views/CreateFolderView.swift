//
//  CreateFolderView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import SwiftUI

struct CreateFolderView: View {
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "cyan"
    
    let parentId: UUID?
    
    let icons = ["folder.fill", "folder.badge.gear", "graduationcap.fill", "book.fill", 
                 "function", "sum", "xmark.seal.fill", "star.fill"]
    let colors = ["cyan", "blue", "purple", "green", "orange", "pink", "yellow", "red"]
    
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
                        
                        Text("Nouveau Dossier")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button(action: createFolder) {
                            Text("Créer")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(color: Theme.neon, verticalPadding: 8, horizontalPadding: 16))
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Preview
                            VStack(spacing: 12) {
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 48))
                                    .foregroundStyle(colorFromString(selectedColor))
                                    .neonGlow(colorFromString(selectedColor), radius: 16)
                                
                                Text(name.isEmpty ? "Mon Dossier" : name)
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
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
                            
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nom")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                TextField("Ex: Mathématiques", text: $name)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            
                            // Icon picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Icône")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                    ForEach(icons, id: \.self) { icon in
                                        Button(action: { selectedIcon = icon }) {
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundStyle(selectedIcon == icon ? .white : .white.opacity(0.5))
                                                .frame(width: 60, height: 60)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(selectedIcon == icon ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(
                                                            selectedIcon == icon ? Color.white.opacity(0.3) : Color.white.opacity(0.1),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                            
                            // Color picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Couleur")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                    ForEach(colors, id: \.self) { color in
                                        Button(action: { selectedColor = color }) {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(colorFromString(color))
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(
                                                            selectedColor == color ? Color.white : Color.clear,
                                                            lineWidth: 3
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createFolder() {
        let folder = Folder(
            name: name,
            icon: selectedIcon,
            color: selectedColor,
            parentId: parentId
        )
        viewModel.addFolder(folder)
        dismiss()
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

