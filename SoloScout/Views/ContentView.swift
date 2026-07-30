//
//  ContentView.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Purpose: Main content view placeholder.
//  Module: Views
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [PhotoLocation]

    var body: some View {
        NavigationStack {
            List {
                ForEach(locations) { location in
                    NavigationLink {
                        Text("Details for \(location.title)")
                    } label: {
                        Text(location.title)
                    }
                }
            }
            .navigationTitle("SoloScout")
            .overlay {
                if locations.isEmpty {
                    ContentUnavailableView(
                        "Keine Fotospots erfasst",
                        systemImage: "camera.macro",
                        description: Text("Erfasse deinen ersten Spot mit der Kamera oder importiere ein Foto aus deiner Bibliothek.")
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PhotoLocation.self, inMemory: true)
}
