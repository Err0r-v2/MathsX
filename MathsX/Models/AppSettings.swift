//
//  AppSettings.swift
//  MathsX
//
//  Created by Stanislas Paquin on 13/10/2025.
//

import Foundation
import Combine

struct AppSettings: Codable {
    var groqApiKey: String
    var mathPixAppId: String
    var mathPixAppKey: String
    
    init(groqApiKey: String = "", mathPixAppId: String = "", mathPixAppKey: String = "") {
        self.groqApiKey = groqApiKey
        self.mathPixAppId = mathPixAppId
        self.mathPixAppKey = mathPixAppKey
    }
}

class SettingsManager: ObservableObject {
    @Published var settings: AppSettings
    
    private let savePath = FileManager.documentsDirectory.appendingPathComponent("settings.json")
    
    init() {
        self.settings = AppSettings()
        loadSettings()
    }
    
    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: savePath)
        } catch {
            print("Unable to save settings: \(error.localizedDescription)")
        }
    }
    
    private func loadSettings() {
        do {
            let data = try Data(contentsOf: savePath)
            settings = try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            print("Unable to load settings: \(error.localizedDescription)")
            settings = AppSettings()
        }
    }
}

