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
        .appendingPathComponent("deadliftdiaries.json")
    
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

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: ([Mesocycle]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: ([Mesocycle]) -> Void
        
        init(onPick: @escaping ([Mesocycle]) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let mesocycles = try decoder.decode([Mesocycle].self, from: data)
                onPick(mesocycles)
            } catch {
                print("Error loading or decoding file: \(error)")
            }
        }
    }
}
