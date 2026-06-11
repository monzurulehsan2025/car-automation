//
//  LocalStorageManager.swift
//  car-automation
//
//  Created by Monzurul Ehsan on 6/11/26.
//

import Foundation

struct LocalStorageManager {
    
    /// File path to inventory JSON within the Documents directory
    private static var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("inventory.json")
    }
    
    /// Serializes and saves the vehicle array locally to disk.
    static func saveVehicles(_ vehicles: [Vehicle]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(vehicles)
            try data.write(to: fileURL, options: [.atomic])
            print("Saved inventory successfully to: \(fileURL.path)")
        } catch {
            print("Error saving inventory offline: \(error.localizedDescription)")
        }
    }
    
    /// Loads and deserializes the vehicle array from local storage.
    static func loadVehicles() -> [Vehicle]? {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let vehicles = try decoder.decode([Vehicle].self, from: data)
            print("Loaded inventory successfully from: \(fileURL.path)")
            return vehicles
        } catch {
            print("No inventory found or error reading from file path: \(error.localizedDescription)")
            return nil
        }
    }
}
