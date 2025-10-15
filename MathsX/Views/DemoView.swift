//
//  DemoView.swift
//  MathsX
//
//  Created by Assistant on 15/10/2025.
//

import SwiftUI

struct DemoView: View {
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text("Démo")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .neonGlow()
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                VStack(spacing: 12) {
                    Image(systemName: "hammer")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Theme.neon)
                        .neonGlow(Theme.neon, radius: 10)
                    Text("En construction")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Cette section sera dédiée à l'apprentissage de démonstrations mathématiques.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

#Preview {
    DemoView()
}
