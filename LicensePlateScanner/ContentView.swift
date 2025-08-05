//
//  ContentView.swift
//  LicensePlateScanner
//
//  Created by OrtonHsieh on 2025/8/5.
//

import SwiftUI

struct ContentView: View {
    @State private var plates: [String] = []
    @State private var toast: String?
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            List(plates, id: \.self) { Text($0).textSelection(.enabled) }
                .navigationTitle("掃描到的車牌")
                .toolbar { Button("開始掃描") { showScanner = true } }
                .sheet(isPresented: $showScanner) {
                    LicensePlateScannerView { message, shouldDismiss in
                        toast = message
                        if shouldDismiss {
                            showScanner = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            toast = nil
                        }
                    }
                    .ignoresSafeArea()
                }
                .overlay {
                    if let toast { ToastView(text: toast) }
                }
        }
    }
}

// ——— 簡易 Toast 元件 ———
struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .transition(.opacity)
            .animation(.easeInOut, value: text)
    }
}
