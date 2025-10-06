//
//  JSONExport.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-10-06.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

func exportToJSON(_ mesocycles: [Mesocycle]) -> Data? {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted
    do {
        let data = try encoder.encode(mesocycles)
        return data
    } catch {
        print("Error encoding mesocycles: \(error)")
        return nil
    }
}

func saveAndShareJSON(_ mesocycles: [Mesocycle]) {
    guard let jsonData = exportToJSON(mesocycles) else { return }
    
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("deadliftdiaries_export.json")
    
    do {
        try jsonData.write(to: tempURL)
        _ = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
    } catch {
        print("Error saving file: \(error)")
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
