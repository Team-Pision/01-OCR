//
//  ContentView.swift
//  VisionKitStudy1
//
//  Created by 여성일 on 6/25/25.
//

import SwiftUI

struct ContentView: View {
  @State private var scannedText: String = ""
  @State private var showScanner = false
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Button("문서 스캔하기") {
          showScanner = true
        }
        .font(.title2)
        
        ScrollView {
          Text(scannedText)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
      }
      .navigationTitle("OCR 문서 스캔")
      .sheet(isPresented: $showScanner) {
        DocumentScannerView(scannedText: $scannedText)
      }
    }
  }
}
#Preview {
  ContentView()
}
