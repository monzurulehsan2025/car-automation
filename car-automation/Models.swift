//
//  Models.swift
//  car-automation
//
//  Created by Monzurul Ehsan on 6/11/26.
//

import Foundation

/// Status of a specific capture guide shot.
enum CaptureStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case captured = "Captured"
    case failed = "Failed AI Check"
}

/// Simulated Core ML output metrics for image quality validation.
struct QualityMetrics: Codable, Equatable, Hashable {
    var blurScore: Double // 0.0 to 1.0, lower is better (sharpness)
    var brightnessScore: Double // 0.0 to 1.0, 0.5 is ideal
    var alignmentScore: Double // 0.0 to 1.0, 1.0 is perfectly aligned
    var backgroundClass: String // E.g., "Clean Lot", "Messy Lot", "Glare/Shadows"
    
    var isBlurApproved: Bool {
        return blurScore < 0.25
    }
    
    var isBrightnessApproved: Bool {
        return brightnessScore >= 0.35 && brightnessScore <= 0.75
    }
    
    var isAlignmentApproved: Bool {
        return alignmentScore >= 0.70
    }
    
    var isBackgroundApproved: Bool {
        return backgroundClass == "Clean Dealership" || backgroundClass == "Clean Lot"
    }
    
    var isApproved: Bool {
        return isBlurApproved && isBrightnessApproved && isAlignmentApproved && isBackgroundApproved
    }
}

/// A specific guide perspective for photographing the vehicle.
struct CaptureGuide: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var symbolName: String
    var status: CaptureStatus
    var capturedImageIndex: Int? // Index to generate mock visual in SwiftUI
    var qualityMetrics: QualityMetrics?
    var isSynced: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, symbolName, status, capturedImageIndex, qualityMetrics, isSynced
    }
    
    init(id: UUID = UUID(), name: String, description: String, symbolName: String, status: CaptureStatus, capturedImageIndex: Int? = nil, qualityMetrics: QualityMetrics? = nil, isSynced: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.symbolName = symbolName
        self.status = status
        self.capturedImageIndex = capturedImageIndex
        self.qualityMetrics = qualityMetrics
        self.isSynced = isSynced
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        symbolName = try container.decode(String.self, forKey: .symbolName)
        status = try container.decode(CaptureStatus.self, forKey: .status)
        capturedImageIndex = try container.decodeIfPresent(Int.self, forKey: .capturedImageIndex)
        qualityMetrics = try container.decodeIfPresent(QualityMetrics.self, forKey: .qualityMetrics)
        isSynced = try container.decodeIfPresent(Bool.self, forKey: .isSynced) ?? true
    }
}

/// A vehicle in the dealership inventory that needs merchandising.
struct Vehicle: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var vin: String
    var year: Int
    var make: String
    var model: String
    var trim: String
    var colorName: String
    var colorHex: String
    var thumbnailSymbol: String // E.g., "sportscartimes"
    var guides: [CaptureGuide]
    
    var progress: Double {
        let completed = guides.filter { $0.status == .captured }.count
        return Double(completed) / Double(guides.count)
    }
    
    var hasUnsyncedPhotos: Bool {
        guides.contains { $0.status == .captured && !$0.isSynced }
    }
    
    var captureStatusText: String {
        let completed = guides.filter { $0.status == .captured }.count
        if completed == 0 {
            return "Pending Capture"
        } else if completed == guides.count {
            return "Completed"
        } else {
            return "In Progress (\(completed)/\(guides.count))"
        }
    }
}
