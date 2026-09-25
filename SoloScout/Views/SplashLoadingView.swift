//
//  SplashLoadingView.swift
//  SoloScout
//
//  Created by Felix & Linus on 25.09.2026.
//  Purpose: Komoot-style pulsing splash screen providing visual feedback during cold-start data loading (SPEC-07).
//  Module: Views
//

import SwiftUI

public struct SplashLoadingView: View {
    @State private var isPulsing = false
    var isICloudSyncEnabled: Bool = false
    
    public init(isICloudSyncEnabled: Bool = false) {
        self.isICloudSyncEnabled = isICloudSyncEnabled
    }
    
    public var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Pulsing SoloScout Camera Brand Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isPulsing ? 1.2 : 0.9)
                        .opacity(isPulsing ? 0.6 : 0.2)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 110, height: 110)
                        .scaleEffect(isPulsing ? 1.1 : 0.95)
                    
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .scaleEffect(isPulsing ? 1.08 : 0.95)
                }
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: isPulsing)
                
                VStack(spacing: 8) {
                    Text("SoloScout")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 6) {
                        if isICloudSyncEnabled {
                            Image(systemName: "icloud.and.arrow.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Mit iCloud synchronisieren...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "internaldrive")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Fotospots werden geladen...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Text("Version 1.2.0 • Festspeicher aktiv")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

#Preview {
    SplashLoadingView(isICloudSyncEnabled: false)
}
