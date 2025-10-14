//
//  SettingsView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var groqApiKey: String = ""
    @State private var mathPixAppId: String = ""
    @State private var mathPixAppKey: String = ""
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(verticalPadding: 8, horizontalPadding: 12))
                        
                        Spacer()
                        
                        Text("Réglages IA")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button(action: saveSettings) {
                            Text("Enregistrer")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(GlowButtonStyle(color: Theme.neon, verticalPadding: 8, horizontalPadding: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Groq API Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 24))
                                        .foregroundStyle(Theme.neon)
                                        .neonGlow(Theme.neon, radius: 8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Groq API")
                                            .font(.title3.bold())
                                            .foregroundStyle(.white)
                                        
                                        Text("Pour la génération de flashcards")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Clé API Groq")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    SecureField("gsk_...", text: $groqApiKey)
                                        .font(.system(size: 14, design: .monospaced))
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
                                
                                Link(destination: URL(string: "https://console.groq.com/keys")!) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "key.fill")
                                        Text("Obtenir une clé API Groq")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .padding(20)
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
                            
                            // MathPix API Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.cyan)
                                        .neonGlow(.cyan, radius: 8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("MathPix API")
                                            .font(.title3.bold())
                                            .foregroundStyle(.white)
                                        
                                        Text("Pour la reconnaissance d'images mathématiques")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("App ID")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    TextField("your_app_id", text: $mathPixAppId)
                                        .font(.system(size: 14, design: .monospaced))
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
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("App Key")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    SecureField("your_app_key", text: $mathPixAppKey)
                                        .font(.system(size: 14, design: .monospaced))
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
                                
                                Link(destination: URL(string: "https://accounts.mathpix.com/ocr-api")!) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "key.fill")
                                        Text("Obtenir une clé API MathPix")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .padding(20)
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
                            
                            // Info section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("À propos")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                }
                                
                                Text("Les clés API sont stockées localement et de manière sécurisée sur votre appareil. Elles ne sont jamais partagées.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadCurrentSettings()
            }
            .alert("Paramètres enregistrés", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vos clés API ont été enregistrées avec succès.")
            }
        }
    }
    
    private func loadCurrentSettings() {
        groqApiKey = settingsManager.settings.groqApiKey
        mathPixAppId = settingsManager.settings.mathPixAppId
        mathPixAppKey = settingsManager.settings.mathPixAppKey
    }
    
    private func saveSettings() {
        settingsManager.settings.groqApiKey = groqApiKey
        settingsManager.settings.mathPixAppId = mathPixAppId
        settingsManager.settings.mathPixAppKey = mathPixAppKey
        settingsManager.saveSettings()
        showingSaveConfirmation = true
    }
}

