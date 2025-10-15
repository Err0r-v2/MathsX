//
//  ContentView.swift
//  MathsX
//
//  Created by Stanislas Paquin on 12/10/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Cartes")
                }
            DemoView()
                .tabItem {
                    Image(systemName: "wand.and.stars")
                    Text("Démo")
                }
        }
    }
}

#Preview {
    ContentView()
}
