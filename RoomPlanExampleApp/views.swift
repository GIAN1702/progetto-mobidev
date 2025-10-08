//
//  views.swift
//  ROOM CamIO
//

import SwiftUI
import RoomPlan

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
                
                After scanning, you can configure what to render and preview before exporting.
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
    @Published var objects: [ObjectConfig] = []
    
    private let allObjectConfigs: [ObjectConfig] = [
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
    
    func filterDetectedObjects(from capturedRoom: CapturedRoom) {
        var detectedCategories = Set<String>()
        
        // Aggiungi sempre "Wall" perché ci sono sempre muri
        detectedCategories.insert("Wall")
        
        // Controlla le finestre
        if !capturedRoom.windows.isEmpty {
            detectedCategories.insert("Window")
        }
        
        // Controlla le porte
        if !capturedRoom.doors.isEmpty {
            detectedCategories.insert("Door")
        }
        
        // Controlla tutti gli oggetti rilevati
        for object in capturedRoom.objects {
            let categoryName = getCategoryName(object.category)
            detectedCategories.insert(categoryName)
        }
        
        // Filtra la lista completa per includere solo le categorie rilevate
        objects = allObjectConfigs.filter { config in
            detectedCategories.contains(config.category)
        }
        
        // Se nessun oggetto è stato rilevato (solo muri), mostra almeno i muri
        if objects.isEmpty {
            objects = allObjectConfigs.filter { $0.category == "Wall" }
        }
    }
    
    private func getCategoryName(_ category: CapturedRoom.Object.Category) -> String {
        switch category {
        case .storage: return "Storage"
        case .refrigerator: return "Refrigetator"
        case .stove: return "Stove"
        case .bed: return "Bed"
        case .sink: return "Sink"
        case .washerDryer: return "Washmachine"
        case .toilet: return "Toilet"
        case .bathtub: return "Bathtub"
        case .oven: return "Oven"
        case .dishwasher: return "Dishwasher"
        case .table: return "Table"
        case .sofa: return "Sofa"
        case .chair: return "Chair"
        case .fireplace: return "Fireplace"
        case .television: return "TV"
        case .stairs: return "Stairs"
        @unknown default: return "Object"
        }
    }
}

// MARK: - ObjectSelectionView (mostrata DOPO la scansione)
struct ObjectSelectionView: View {
    @StateObject private var viewModel = ObjectSelectionViewModel()
    @State private var showingPreview = false
    let capturedRoom: CapturedRoom
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
                        ObjectRow(object: $viewModel.objects[index])
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingPreview = true
                        }) {
                            Text("Preview & Export")
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
            .navigationTitle("Select Objects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingPreview) {
                TemplatePreviewView(
                    capturedRoom: capturedRoom,
                    objectConfig: viewModel.objects
                )
            }
            .onAppear {
                // Filtra gli oggetti al primo caricamento della view
                viewModel.filterDetectedObjects(from: capturedRoom)
            }
        }
    }
}

// MARK: - ObjectRow
struct ObjectRow: View {
    @Binding var object: ObjectConfig
    
    var body: some View {
        HStack(spacing: 12) {
            Text(object.name)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: $object.renderInTemplate)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .frame(width: 80)
                .onChange(of: object.renderInTemplate) { newValue in
                    if !newValue {
                       object.renderInColorMap = false
                    } else {
                        object.renderInColorMap = true
                    }
                }
            
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
                Color.clear.frame(width: 50)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - TemplatePreviewView (NUOVA - mostra l'anteprima prima di esportare)
struct TemplatePreviewView: View {
    let capturedRoom: CapturedRoom
    let objectConfig: [ObjectConfig]
    
    @State private var templateImage: UIImage?
    @State private var isGenerating = true
    @State private var showingExportSheet = false
    @State private var camioFileURL: URL?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                if isGenerating {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                        Text("Generating preview...")
                            .foregroundColor(.gray)
                    }
                } else if let image = templateImage {
                    VStack(spacing: 0) {
                        // Immagine a larghezza schermo
                        GeometryReader { geometry in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width)
                        }
                        
                        // Bottone Export sotto
                        VStack(spacing: 20) {
                            Button(action: {
                                exportToCamIO()
                            }) {
                                Text("Export")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: 200)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(25)
                            }
                            .disabled(isGenerating)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                    }
                } else {
                    Text("Error generating preview")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Template Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            generatePreview()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = camioFileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func generatePreview() {
        DispatchQueue.global(qos: .userInitiated).async {
            let converter = RoomPlanToCamIOConverter()
            converter.objectConfig = objectConfig
            
            let (template, _) = converter.renderWithPriority(from: capturedRoom)
            
            DispatchQueue.main.async {
                self.templateImage = template
                self.isGenerating = false
            }
        }
    }
    
    private func exportToCamIO() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let converter = RoomPlanToCamIOConverter()
            converter.objectConfig = objectConfig
            
            if let url = converter.convertToCamIO(from: capturedRoom) {
                DispatchQueue.main.async {
                    self.camioFileURL = url
                    self.isGenerating = false
                    self.showingExportSheet = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - RoomCaptureViewWrapper (modificato per non passare objectConfig)
struct RoomCaptureViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = RoomCaptureViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
