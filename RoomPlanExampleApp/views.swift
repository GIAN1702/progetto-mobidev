//
//  views.swift
//  ROOM CamIO
//
//  Created by Students on 08/10/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

// MARK: - ContentView (Schermata principale)
struct ContentView: View {
    @State private var showingScanView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Text("Room CAM-I/O")
                    .font(.system(size: 34, weight: .bold))
                
                Text("""
                To scan your room, point your device at all the walls, windows, doors and furniture in your space until your scan is complete.
                
                then click export for the camio compatible project
                """)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    showingScanView = true
                }) {
                    Text("Start Scanning")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .padding(.bottom, 33)
            }
            .fullScreenCover(isPresented: $showingScanView) {
                RoomCaptureViewWrapper()
            }
        }
    }
}

// MARK: - UnsupportedDeviceView
struct UnsupportedDeviceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Unsupported Device")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("This sample app requires a device with a LiDAR Scanner.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - RoomCaptureViewWrapper
struct RoomCaptureViewWrapper: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = RoomCaptureViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Non serve aggiornare nulla
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
