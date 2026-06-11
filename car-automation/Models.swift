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
