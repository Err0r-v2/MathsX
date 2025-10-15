//
//  ContentView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct ContentView: View {
    enum Tab { case cartes, demo }
    @State private var selected: Tab = .cartes

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .cartes:
                    HomeView()
                case .demo:
                    DemoView()
                }
            }
            .ignoresSafeArea(.keyboard)

            CustomBottomBar(selected: $selected)
        }
    }
}

struct CustomBottomBar: View {
    @Binding var selected: ContentView.Tab

    var body: some View {
        HStack(spacing: 20) {
            bottomItem(icon: "square.grid.2x2", title: "Cartes", tab: .cartes)
            bottomItem(icon: "wand.and.stars", title: "Démo", tab: .demo)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            .ultraThinMaterial
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func bottomItem(icon: String, title: String, tab: ContentView.Tab) -> some View {
        let isSelected = selected == tab
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selected = tab } }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.neon : .white.opacity(0.8))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Theme.neon.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
