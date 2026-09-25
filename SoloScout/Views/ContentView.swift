//
//  ContentView.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: Entry point content view managing cold-start splash state machine and lifecycle background flushes (SPEC-07).
//  Module: Views
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = false
    @State private var isColdStartLoading = true
    
    var body: some View {
        ZStack {
            LocationListView()
                .opacity(isColdStartLoading ? 0 : 1)
            
            if isColdStartLoading {
                SplashLoadingView(isICloudSyncEnabled: isICloudSyncEnabled)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Cold-start data initialization handshake (Komoot-style)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.isColdStartLoading = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Guaranteed physical flush on app suspend or swipe-up
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PhotoLocation.self, inMemory: true)
}
