//
//  ContentView.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Purpose: Entry point content view displaying the main LocationListView.
//  Module: Views
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        LocationListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PhotoLocation.self, inMemory: true)
}
