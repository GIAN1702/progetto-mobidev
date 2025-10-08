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
    @State private var showingObjectSelection = false
    
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
                    showingObjectSelection = true
                }) {
                    Text("Configure & Scan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .padding(.bottom, 33)
            }
            .fullScreenCover(isPresented: $showingObjectSelection) {
                ObjectSelectionView()
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

// MARK: - Configurazione oggetto
struct ObjectConfig: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: String
    var renderInTemplate: Bool
    var renderInColorMap: Bool
    
    static func == (lhs: ObjectConfig, rhs: ObjectConfig) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ObjectSelectionViewModel
class ObjectSelectionViewModel: ObservableObject {
    @Published var objects: [ObjectConfig] = [
        ObjectConfig(name: "Window", category: "Window", renderInTemplate: false, renderInColorMap: true),
        ObjectConfig(name: "Stairs", category: "Stairs", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Table", category: "Table", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Chair", category: "Chair", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Storage", category: "Storage", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Toilet", category: "Toilet", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Refrigerator", category: "Refrigetator", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Stove", category: "Stove", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Bed", category: "Bed", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Sink", category: "Sink", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Washer/Dryer", category: "Washmachine", renderInTemplate: false, renderInColorMap: false),
       
        ObjectConfig(name: "Bathtub", category: "Bathtub", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Oven", category: "Oven", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Dishwasher", category: "Dishwasher", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Sofa", category: "Sofa", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Fireplace", category: "Fireplace", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Television", category: "TV", renderInTemplate: false, renderInColorMap: false),
        ObjectConfig(name: "Other Objects", category: "Object", renderInTemplate: false, renderInColorMap: false)
    ]
    
    func getConfig(for category: String) -> ObjectConfig? {
        return objects.first { $0.category == category }
    }
}

// MARK: - ObjectSelectionView
struct ObjectSelectionView: View {
    @StateObject private var viewModel = ObjectSelectionViewModel()
    @State private var showingScanView = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header:
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configure Objects to Render")
                            .font(.headline)
                        HStack {
                            Spacer()
                            Text("Map")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80)
                            Text("CamIO")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50)
                        }
                    }
                ) {
                    ForEach(viewModel.objects.indices, id: \.self) { index in
                        ObjectRow(
                            object: $viewModel.objects[index]
                        )
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingScanView = true
                        }) {
                            Text("Start Scanning")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(25)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Object Selection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingScanView) {
                RoomCaptureViewWrapper(objectConfig: viewModel.objects)
            }
        }
    }
}

// MARK: - ObjectRow
struct ObjectRow: View {
    @Binding var object: ObjectConfig
    
    var body: some View {
        HStack(spacing: 12) {
            // Nome oggetto
            Text(object.name)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Toggle per template
            Toggle("", isOn: $object.renderInTemplate)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .frame(width: 80)
                .onChange(of: object.renderInTemplate) { newValue in
                    // Se disattivo il template, attivo automaticamente la colorMap
                    if !newValue {
                       object.renderInColorMap = false
                    }else{
                        object.renderInColorMap = true
                    }
                }
            
            // Checkbox per colorMap (visibile solo se template è OFF)
            if !object.renderInTemplate {
                Button(action: {
                    object.renderInColorMap.toggle()
                }) {
                    Image(systemName: object.renderInColorMap ? "checkmark.square.fill" : "square")
                        .foregroundColor(object.renderInColorMap ? .blue : .gray)
                        .font(.title2)
                }
                .frame(width: 50)
            } else {
                // Spazio vuoto per allineamento
                Color.clear.frame(width: 50)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - RoomCaptureViewWrapper
struct RoomCaptureViewWrapper: UIViewControllerRepresentable {
    let objectConfig: [ObjectConfig]
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = RoomCaptureViewController()
        viewController.objectConfig = objectConfig
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
