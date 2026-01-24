//
//  JSONExport.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-10-06.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ExportData: Codable {
    let mesocycles: [Mesocycle]
    let templates: [ExerciseTemplate]
    let history: [ExerciseHistory]
}

func exportToJSON(_ mesocycles: [Mesocycle], templates: [ExerciseTemplate], history: [ExerciseHistory]) -> Data? {
    let exportData = ExportData(mesocycles: mesocycles, templates: templates, history: history)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = .prettyPrinted
    do {
        let data = try encoder.encode(exportData)
        return data
    } catch {
        print("Error encoding data: \(error)")
        return nil
    }
}

func saveAndShareJSON(_ mesocycles: [Mesocycle], templates: [ExerciseTemplate], history: [ExerciseHistory]) {
    guard let jsonData = exportToJSON(mesocycles, templates: templates, history: history) else { return }
    
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
    var onPick: ([Mesocycle], [ExerciseTemplate], [ExerciseHistory], [UUID: UUID]) -> Void
    
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
        var onPick: ([Mesocycle], [ExerciseTemplate], [ExerciseHistory], [UUID: UUID]) -> Void
        
        init(onPick: @escaping ([Mesocycle], [ExerciseTemplate], [ExerciseHistory], [UUID: UUID]) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                if let exportData = try? decoder.decode(ExportData.self, from: data) {
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let historyArray = jsonObject["history"] as? [[String: Any]] {
                        
                        var historyToTemplateMap: [UUID: UUID] = [:]
                        for historyDict in historyArray {
                            if let historyIDString = historyDict["id"] as? String,
                               let historyID = UUID(uuidString: historyIDString),
                               let templateIDString = historyDict["templateID"] as? String,
                               let templateID = UUID(uuidString: templateIDString) {
                                historyToTemplateMap[historyID] = templateID
                            }
                        }
                        
                        onPick(exportData.mesocycles, exportData.templates, exportData.history, historyToTemplateMap)
                    } else {
                        onPick(exportData.mesocycles, exportData.templates, exportData.history, [:])
                    }
                } else {
                    // Fallback to old format (only mesocycles)
                    let mesocycles = try decoder.decode([Mesocycle].self, from: data)
                    onPick(mesocycles, [], [], [:])
                }
            } catch {
                print("Error loading or decoding file: \(error)")
            }
        }
    }
}
