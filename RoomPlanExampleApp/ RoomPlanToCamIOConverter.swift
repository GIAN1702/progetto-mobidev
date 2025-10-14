//
//  RoomPlanToCamIOConverter.swift
//  ROOM CamIO
//

import UIKit
import RoomPlan
import SceneKit
import ZIPFoundation

// MARK: - CamIO Data Structures

struct CamIOHotspot: Codable {
    let color: [Int]
    let hotspotTitle: String
    let hotspotDescription: String?
    let sound: String?
}

struct CamIOData: Codable {
    let title: String
    let shortDescription: String
    let longDescription: String
    let creationDate: String
    let lastUpdate: String
    let lang: String
    let hotspots: [CamIOHotspot]
}

// MARK: - RoomPlan to CamIO Converter

class RoomPlanToCamIOConverter {
    
    var objectConfig: [ObjectConfig] = []
    var rotation: Double = 0
    
    private var objectColorMap: [String: [Int]] = [:]
    private var occorrenze: [String: Int] = [:]
    private let renderSize: CGFloat = 2048
    private let SPESSORE: CGFloat = 20.0
    private let DIMENSIONE_CROCETTA: CGFloat = 60.0
    
    private func shouldRender(_ category: String, inTemplate: Bool) -> Bool {
        guard let config = objectConfig.first(where: { $0.category == category }) else {
            return true
        }
        return inTemplate ? config.renderInTemplate : config.renderInColorMap
    }
    
    func convertToCamIO(from result: CapturedRoom) -> URL? {
        let (templateImage, colorMapImage) = renderWithPriority(from: result)
        
        guard let template = templateImage, let colorMap = colorMapImage else {
            return nil
        }
        
        let data = createCamIOData()
        
        return createCamIOFile(template: template, colorMap: colorMap, data: data)
    }
    
    // NEW METHOD: Render for rotation preview (without corner symbols and with 25% margin)
    func renderForRotationPreview(from result: CapturedRoom) -> (UIImage?, UIImage?) {
        let originalRotation = rotation
        rotation = 0  // Temporarily set rotation to 0 for preview
        
        var minBounds = simd_float3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxBounds = simd_float3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
        
        for wall in result.walls {
            let position = simd_float3(wall.transform.columns.3.x, wall.transform.columns.3.y, wall.transform.columns.3.z)
            let halfDims = wall.dimensions * 0.5
            minBounds = simd_min(minBounds, position - halfDims)
            maxBounds = simd_max(maxBounds, position + halfDims)
        }
        
        for object in result.objects {
            let position = simd_float3(object.transform.columns.3.x, object.transform.columns.3.y, object.transform.columns.3.z)
            let halfDims = object.dimensions * 0.5
            minBounds = simd_min(minBounds, position - halfDims)
            maxBounds = simd_max(maxBounds, position + halfDims)
        }
        
        let sceneCenter = (minBounds + maxBounds) * 0.5
        let sceneDimensions = maxBounds - minBounds
        let maxDimension = max(sceneDimensions.x, sceneDimensions.z) * 2.0  // Doubled for 25% margin on each side
        
        let size = CGSize(width: renderSize, height: renderSize)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            rotation = originalRotation
            return (nil, nil)
        }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        var elementsToRender: [(priority: Int, render: (CGContext) -> Void)] = []
        
        var categoryPriorityMap: [String: Int] = [:]
        let totalObjects = objectConfig.count
        for (index, config) in objectConfig.enumerated() {
            categoryPriorityMap[config.category] = totalObjects - index
        }
        
        func getPriority(for category: String) -> Int {
            return categoryPriorityMap[category] ?? 0
        }
        
        // Render walls
        for surface in result.walls {
            let priority = getPriority(for: "Wall")
            elementsToRender.append((priority: priority, render: { context in
                self.drawWall(surface, color: [255,255,255], context: context,
                             sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
            }))
        }
        
        // Render windows
        for window in result.windows {
            if !shouldRender("Window", inTemplate: true) { continue }
            let priority = getPriority(for: "Window")
            elementsToRender.append((priority: priority, render: { context in
                self.drawWindow(window, color: [255,255,255], context: context,
                               sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
            }))
        }
        
        // Render doors
        for door in result.doors {
            if !shouldRender("Door", inTemplate: true) { continue }
            let priority = getPriority(for: "Door")
            elementsToRender.append((priority: priority, render: { context in
                self.drawDoor(door, color: [255,255,255], context: context,
                             sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
            }))
        }
        
        // Render objects
        for object in result.objects {
            let categoryName = getCategoryName(object.category)
            if !shouldRender(categoryName, inTemplate: true) { continue }
            let priority = getPriority(for: categoryName)
            elementsToRender.append((priority: priority, render: { context in
                self.drawObject(object, color: [255,255,255], context: context,
                               sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
            }))
        }
        
        elementsToRender.sort { $0.priority < $1.priority }
        
        for element in elementsToRender {
            element.render(context)
        }
        
        let template = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        rotation = originalRotation
        return (template, nil)
    }
    
    func renderWithPriority(from result: CapturedRoom) -> (UIImage?, UIImage?) {
        var minBounds = simd_float3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxBounds = simd_float3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
        
        for wall in result.walls {
            let position = simd_float3(wall.transform.columns.3.x, wall.transform.columns.3.y, wall.transform.columns.3.z)
            let halfDims = wall.dimensions * 0.5
            minBounds = simd_min(minBounds, position - halfDims)
            maxBounds = simd_max(maxBounds, position + halfDims)
        }
        
        for object in result.objects {
            let position = simd_float3(object.transform.columns.3.x, object.transform.columns.3.y, object.transform.columns.3.z)
            let halfDims = object.dimensions * 0.5
            minBounds = simd_min(minBounds, position - halfDims)
            maxBounds = simd_max(maxBounds, position + halfDims)
        }
        
        let sceneCenter = (minBounds + maxBounds) * 0.5
        let sceneDimensions = maxBounds - minBounds
        let maxDimension = max(sceneDimensions.x, sceneDimensions.z) * 1.1
        
        let size = CGSize(width: renderSize, height: renderSize)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return (nil, nil) }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        var elementsToRender: [(priority: Int, render: [(CGContext) -> Void])] = []
        
        // Crea una mappa delle priorità basata sull'ordine in objectConfig
        var categoryPriorityMap: [String: Int] = [:]
        let totalObjects = objectConfig.count
        for (index, config) in objectConfig.enumerated() {
            categoryPriorityMap[config.category] = totalObjects - index
        }
        
        func getPriority(for category: String) -> Int {
            return categoryPriorityMap[category] ?? 0
        }
        
        for (_, surface) in result.walls.enumerated() {
            let priority = getPriority(for: "Wall")
            let color = getColor(surface.transform)
            if occorrenze["Wall"] == nil {
                occorrenze["Wall"] = 1
            } else {
                occorrenze["Wall"]! += 1
            }
            objectColorMap["Wall \(occorrenze["Wall"]!)"] = color
            
            elementsToRender.append((priority: priority, render: [{
                context in
                self.drawWall(surface, color: color, context: context,
                             sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
            },{
                context in
                self.drawWall(surface, color: [255,255,255], context: context,
                             sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
            }]))
        }
        
        for (_, window) in result.windows.enumerated() {
            if !shouldRender("Window", inTemplate: true) && !shouldRender("Window", inTemplate: false) {
                continue
            }
            
            let priority = getPriority(for: "Window")
            let color = getColor(window.transform)
            if occorrenze["Window"] == nil {
                occorrenze["Window"] = 1
            } else {
                occorrenze["Window"]! += 1
            }
            objectColorMap["Window \(occorrenze["Window"]!)"] = color
            
            let renderInTemplate = shouldRender("Window", inTemplate: true)
            let renderInColorMap = shouldRender("Window", inTemplate: false)
            
            elementsToRender.append((priority: priority, render: [{
                context in
                if renderInColorMap {
                    self.drawWindow(window, color: color, context: context,
                                   sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
                }
            },{
                context in
                if renderInTemplate {
                    self.drawWindow(window, color: [255,255,255], context: context,
                                   sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
                }
            }]))
        }
        
        for (_, door) in result.doors.enumerated() {
            if !shouldRender("Door", inTemplate: true) && !shouldRender("Door", inTemplate: false) {
                continue
            }
            
            let priority = getPriority(for: "Door")
            let color = getColor(door.transform)
            if occorrenze["Door"] == nil {
                occorrenze["Door"] = 1
            } else {
                occorrenze["Door"]! += 1
            }
            objectColorMap["Door \(occorrenze["Door"]!)"] = color
            
            let renderInTemplate = shouldRender("Door", inTemplate: true)
            let renderInColorMap = shouldRender("Door", inTemplate: false)
            
            elementsToRender.append((priority: priority, render: [{
                context in
                if renderInColorMap {
                    self.drawDoor(door, color: color, context: context,
                                 sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
                }
            },{
                context in
                if renderInTemplate {
                    self.drawDoor(door, color: [255,255,255], context: context,
                                 sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
                }
            }]))
        }
        
        for object in result.objects {
            let categoryName = getCategoryName(object.category)
            
            if !shouldRender(categoryName, inTemplate: true) && !shouldRender(categoryName, inTemplate: false) {
                continue
            }
            
            let priority = getPriority(for: categoryName)
            let color = getColor(object.transform)
            if occorrenze[categoryName] == nil {
                occorrenze[categoryName] = 1
            } else {
                occorrenze[categoryName]! += 1
            }
            objectColorMap["\(categoryName) \(occorrenze[categoryName]!)"] = color
            
            let renderInTemplate = shouldRender(categoryName, inTemplate: true)
            let renderInColorMap = shouldRender(categoryName, inTemplate: false)
            
            elementsToRender.append((priority: priority, render: [{
                context in
                if renderInColorMap {
                    self.drawObject(object, color: color, context: context,
                                   sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
                }
            },{
                context in
                if renderInTemplate {
                    self.drawObject(object, color: [255,255,255], context: context,
                                   sceneCenter: sceneCenter, maxDimension: maxDimension, size: size)
                }
            }]))
        }
        
        // Ordina per priorità
        elementsToRender.sort { $0.priority < $1.priority }
        
        // Render ColorMap
        for element in elementsToRender {
            element.render[0](context)
        }
        
        let colorMap = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Render Template
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return (nil, nil) }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        for element in elementsToRender {
            element.render[1](context)
        }
        
        drawCornerCrosses(context: context, size: size)
           
        let template = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
           
        return (template, colorMap)
    }
       
    private func drawCornerCrosses(context: CGContext, size: CGSize) {
        let margin: CGFloat = 30.0
        var smallShapeSize: CGFloat = 80.0
        let spacing: CGFloat = 5.0
        let fontSize: CGFloat = 50.0
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let topRight = "CamIO Explorer" as NSString
        let topRightSize = topRight.size(withAttributes: attributes)
        topRight.draw(at: CGPoint(x: size.width - margin - topRightSize.width, y: margin), withAttributes: attributes)
        
        let bottomLeft = "University of Milan" as NSString
        let bottomLeftSize = bottomLeft.size(withAttributes: attributes)
        bottomLeft.draw(at: CGPoint(x: margin, y: size.height - margin - bottomLeftSize.height), withAttributes: attributes)
        
        context.setFillColor(UIColor(white: 0.0, alpha: 1.0).cgColor)
        context.fill(CGRect(x: margin, y: margin, width: smallShapeSize, height: smallShapeSize))
        
        context.setFillColor(UIColor(white: 0.50, alpha: 1.0).cgColor)
        context.fill(CGRect(x: margin + smallShapeSize + spacing, y: margin,
                           width: smallShapeSize, height: smallShapeSize))
        
        context.setFillColor(UIColor(white: 0.8, alpha: 1.0).cgColor)
        context.fill(CGRect(x: margin, y: margin + smallShapeSize + spacing,
                           width: smallShapeSize, height: smallShapeSize))
        
        smallShapeSize = 40.0
                   
        let bottomRightX = size.width - margin - (2 * smallShapeSize + spacing)
        let bottomRightY = size.height - margin - (2 * smallShapeSize + spacing)
        
        context.setFillColor(UIColor(white: 1.0, alpha: 1.0).cgColor)
        context.fillEllipse(in: CGRect(x: bottomRightX, y: bottomRightY,
                                      width: smallShapeSize, height: smallShapeSize))
        
        context.setFillColor(UIColor(white: 0.75, alpha: 1.0).cgColor)
        context.fillEllipse(in: CGRect(x: bottomRightX + smallShapeSize + spacing, y: bottomRightY,
                                      width: smallShapeSize, height: smallShapeSize))
        
        context.setFillColor(UIColor(white: 0.5, alpha: 1.0).cgColor)
        context.fillEllipse(in: CGRect(x: bottomRightX, y: bottomRightY + smallShapeSize + spacing,
                                      width: smallShapeSize, height: smallShapeSize))
        
        context.setFillColor(UIColor(white: 0.0, alpha: 1.0).cgColor)
        context.fillEllipse(in: CGRect(x: bottomRightX + smallShapeSize + spacing,
                                      y: bottomRightY + smallShapeSize + spacing,
                                      width: smallShapeSize, height: smallShapeSize))
    }
    
    private func drawWall(_ wall: CapturedRoom.Surface, color: [Int], context: CGContext,
                          sceneCenter: simd_float3, maxDimension: Float, size: CGSize) {
        let position = simd_float3(wall.transform.columns.3.x, wall.transform.columns.3.y, wall.transform.columns.3.z)
        
        let x = CGFloat((position.x - sceneCenter.x) / maxDimension + 0.5) * size.width
        let z = CGFloat((position.z - sceneCenter.z) / maxDimension + 0.5) * size.height
        
        let width = CGFloat(wall.dimensions.x / maxDimension) * size.width
        let thickness = CGFloat(0.3 / maxDimension) * size.width
        
        let wallRotation = atan2(wall.transform.columns.0.z, wall.transform.columns.0.x)
        
        context.saveGState()
        context.translateBy(x: x, y: z)
        context.rotate(by: CGFloat(wallRotation + Float(rotation * .pi / 180)))
        
        if (color == [255,255,255]){
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(SPESSORE)
            context.move(to: CGPoint(x: -width/2, y: 0))
            context.addLine(to: CGPoint(x: width/2, y: 0))
            context.strokePath()
        }else{
            let rect = CGRect(x: -width/2, y: -thickness/2, width: width, height: thickness)
            context.setFillColor(UIColor(red: CGFloat(color[0])/255.0,
                                        green: CGFloat(color[1])/255.0,
                                        blue: CGFloat(color[2])/255.0,
                                        alpha: 1.0).cgColor)
            context.fill(rect)
        }
        context.restoreGState()
    }
    
    private func drawWindow(_ window: CapturedRoom.Surface, color: [Int], context: CGContext,
                            sceneCenter: simd_float3, maxDimension: Float, size: CGSize) {
        let position = simd_float3(window.transform.columns.3.x, window.transform.columns.3.y, window.transform.columns.3.z)
        
        let x = CGFloat((position.x - sceneCenter.x) / maxDimension + 0.5) * size.width
        let z = CGFloat((position.z - sceneCenter.z) / maxDimension + 0.5) * size.height
        
        let width = CGFloat(window.dimensions.x / maxDimension) * size.width
        let thickness = CGFloat(0.3 / maxDimension) * size.width
        
        let windowRotation = atan2(window.transform.columns.0.z, window.transform.columns.0.x)
        
        context.saveGState()
        context.translateBy(x: x, y: z)
        context.rotate(by: CGFloat(windowRotation + Float(rotation * .pi / 180)))
        
        let rect = CGRect(x: -width/2, y: -thickness/2, width: width, height: thickness)

        if (color == [255,255,255]){
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(SPESSORE)
            context.stroke(rect)
            context.setFillColor(UIColor(red: CGFloat(color[0])/255.0,
                                        green: CGFloat(color[1])/255.0,
                                        blue: CGFloat(color[2])/255.0,
                                        alpha: 1.0).cgColor)
            context.fill(rect)
        }else{
            context.setFillColor(UIColor(red: CGFloat(color[0])/255.0,
                                        green: CGFloat(color[1])/255.0,
                                        blue: CGFloat(color[2])/255.0,
                                        alpha: 1.0).cgColor)
            context.fill(rect)
        }
        
        context.restoreGState()
    }
    
    private func drawDoor(_ door: CapturedRoom.Surface, color: [Int], context: CGContext,
                          sceneCenter: simd_float3, maxDimension: Float, size: CGSize) {
        let position = simd_float3(door.transform.columns.3.x, door.transform.columns.3.y, door.transform.columns.3.z)
        
        let x = CGFloat((position.x - sceneCenter.x) / maxDimension + 0.5) * size.width
        let z = CGFloat((position.z - sceneCenter.z) / maxDimension + 0.5) * size.height
        
        let width = CGFloat(door.dimensions.x / maxDimension) * size.width
        let thickness = CGFloat(0.4 / maxDimension) * size.width
        
        let doorRotation = atan2(door.transform.columns.0.z, door.transform.columns.0.x)
        
        context.saveGState()
        context.translateBy(x: x, y: z)
        context.rotate(by: CGFloat(doorRotation + Float(rotation * .pi / 180)))
        
        let rect = CGRect(x: -width/2, y: -thickness/2, width: width, height: thickness)
        context.setFillColor(UIColor(red: CGFloat(color[0])/255.0,
                                    green: CGFloat(color[1])/255.0,
                                    blue: CGFloat(color[2])/255.0,
                                    alpha: 1.0).cgColor)
        context.fill(rect)
        
        context.restoreGState()
    }
    
    private func drawObject(_ object: CapturedRoom.Object, color: [Int], context: CGContext,
                           sceneCenter: simd_float3, maxDimension: Float, size: CGSize) {
        let position = simd_float3(object.transform.columns.3.x, object.transform.columns.3.y, object.transform.columns.3.z)
        
        let x = CGFloat((position.x - sceneCenter.x) / maxDimension + 0.5) * size.width
        let z = CGFloat((position.z - sceneCenter.z) / maxDimension + 0.5) * size.height
        
        let width = CGFloat(object.dimensions.x / maxDimension) * size.width
        let depth = CGFloat(object.dimensions.z / maxDimension) * size.height
        
        let objectRotation = atan2(object.transform.columns.0.z, object.transform.columns.0.x)
        
        context.saveGState()
        context.translateBy(x: x, y: z)
        context.rotate(by: CGFloat(objectRotation + Float(rotation * .pi / 180)))
        
        let rect = CGRect(x: -width/2, y: -depth/2, width: width, height: depth)
        context.setFillColor(UIColor(red: CGFloat(color[0])/255.0,
                                    green: CGFloat(color[1])/255.0,
                                    blue: CGFloat(color[2])/255.0,
                                    alpha: 1.0).cgColor)
        context.fill(rect)
        if (color == [255,255,255]){
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(SPESSORE)
            context.stroke(rect)
        }
        
        context.restoreGState()
    }
    
    private func createCamIOData() -> CamIOData {
        var hotspots: [CamIOHotspot] = []
        
        for (name, color) in objectColorMap {
            let hotspot = CamIOHotspot(
                color: color,
                hotspotTitle: name,
                hotspotDescription: "",
                sound: nil
            )
            hotspots.append(hotspot)
        }
        
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        
        return CamIOData(
            title: "Room Scan",
            shortDescription: "Tactile map",
            longDescription: "3D scan of the room converted to a tactile map",
            creationDate: now,
            lastUpdate: now,
            lang: "en",
            hotspots: hotspots
        )
    }
    
    private func createCamIOFile(template: UIImage, colorMap: UIImage, data: CamIOData) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = Int(Date().timeIntervalSince1970)
        let camioURL = tempDir.appendingPathComponent("room_\(timestamp).camio")
        
        do {
            guard let archive = Archive(url: camioURL, accessMode: .create) else {
                return nil
            }
            
            if let templateData = template.pngData() {
                try archive.addEntry(with: "template.png", type: .file, uncompressedSize: UInt32(templateData.count), provider: { position, size in
                    return templateData.subdata(in: position..<position+size)
                })
            }
            
            if let colorMapData = colorMap.pngData() {
                try archive.addEntry(with: "colorMap.png", type: .file, uncompressedSize: UInt32(colorMapData.count), provider: { position, size in
                    return colorMapData.subdata(in: position..<position+size)
                })
            }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try archive.addEntry(with: "data.json", type: .file, uncompressedSize: UInt32(jsonData.count), provider: { position, size in
                return jsonData.subdata(in: position..<position+size)
            })
            
            let emptyData = Data()
            try archive.addEntry(
                with: "sounds/.keep",
                type: .file,
                uncompressedSize: UInt32(emptyData.count),
                compressionMethod: .none,
                provider: { position, size in
                    return emptyData.subdata(in: position..<position+size)
                }
            )
            
            return camioURL
            
        } catch {
            print("Error generating .camio: \(error)")
            return nil
        }
    }
    
    private func getColor(_ transform: simd_float4x4) -> [Int] {
        let x = transform.columns.3.x
        let y = transform.columns.3.y
        let z = transform.columns.3.z
        
        let seed = abs(Int(x * 1000) + Int(y * 1000) * 31 + Int(z * 1000) * 97)
        
        let r = (seed * 17) % 256
        let g = (seed * 23) % 256
        let b = (seed * 31) % 256
        
        let luminance = 0.2126 * Float(r) + 0.7152 * Float(g) + 0.0722 * Float(b)
        
        let targetLuminance = Float(Int(luminance) % 126 + 25)
        let scale = targetLuminance / luminance
        
        let finalR = max(0, min(255, Int(Float(r) * scale)))
        let finalG = max(0, min(255, Int(Float(g) * scale)))
        let finalB = max(0, min(255, Int(Float(b) * scale)))
        
        return [finalR, finalG, finalB]
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
