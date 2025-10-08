
//

import SwiftUI
import RoomPlan

// MARK: - Configurazione oggetto
struct ObjectConfig: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    var renderInTemplate: Bool
    var renderInColorMap: Bool
}

// MARK: - ObjectSelectionViewModel
class ObjectSelectionViewModel: ObservableObject {
    @Published var objects: [ObjectConfig] = [
        ObjectConfig(name: "Wall", category: "Wall", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Window", category: "Window", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Door", category: "Door", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Storage", category: "Storage", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Refrigerator", category: "Refrigetator", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Stove", category: "Stove", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Bed", category: "Bed", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Sink", category: "Sink", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Washer/Dryer", category: "Washmachine", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Toilet", category: "Toilet", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Bathtub", category: "Bathtub", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Oven", category: "Oven", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Dishwasher", category: "Dishwasher", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Table", category: "Table", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Sofa", category: "Sofa", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Chair", category: "Chair", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Fireplace", category: "Fireplace", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Television", category: "TV", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Stairs", category: "Stairs", renderInTemplate: true, renderInColorMap: true),
        ObjectConfig(name: "Other Objects", category: "Object", renderInTemplate: true, renderInColorMap: true)
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
                Section(header: Text("Configure Objects to Detect")) {
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
                .onChange(of: object.renderInTemplate) { newValue in
                    // Se disattivo il template, attivo automaticamente la colorMap
                    if !newValue {
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
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct ObjectSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectSelectionView()
    }
}
