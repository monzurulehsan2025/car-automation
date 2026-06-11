//
//  CaptureViewModel.swift
//  car-automation
//
//  Created by Monzurul Ehsan on 6/11/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CaptureViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var vehicles: [Vehicle] = []
    @Published var selectedVehicle: Vehicle?
    @Published var activeGuide: CaptureGuide?
    
    // Viewfinder Camera Simulation
    @Published var isCameraActive: Bool = false
    @Published var cameraZoom: CGFloat = 1.0
    @Published var isFlashOn: Bool = false
    @Published var gyroRoll: Double = 8.5 // Simulated deviation
    @Published var gyroPitch: Double = -5.0 // Simulated deviation
    @Published var isCameraShutterFlashing: Bool = false
    
    // CoreML Analysis Simulation
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    @Published var analysisStepMessage: String = ""
    @Published var tempMetrics: QualityMetrics?
    @Published var showQualityReport: Bool = false
    @Published var lastCapturedIndex: Int?
    
    // Offline Cloud Sync Simulation
    @Published var isSyncing: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var syncMessage: String = ""
    
    // MARK: - Private Timer
    private var analysisTimer: Timer?
    private var gyroTimer: Timer?
    
    // MARK: - Computed Properties
    var isStabilized: Bool {
        abs(gyroRoll) < 1.0 && abs(gyroPitch) < 1.0
    }
    
    // MARK: - Initializer
    init() {
        if let stored = LocalStorageManager.loadVehicles() {
            self.vehicles = stored
            self.selectedVehicle = stored.first
        } else {
            seedInitialVehicles()
            LocalStorageManager.saveVehicles(vehicles)
        }
        startSimulatingGyroDrift()
    }
    
    // MARK: - Public Methods
    
    /// Selects a vehicle and updates the active selection.
    func selectVehicle(_ vehicle: Vehicle) {
        self.selectedVehicle = vehicle
    }
    
    /// Launches the capture session for a specific guide photo.
    func startCapture(for guide: CaptureGuide) {
        self.activeGuide = guide
        self.isCameraActive = true
        self.showQualityReport = false
        self.isAnalyzing = false
        self.analysisProgress = 0.0
        self.analysisStepMessage = ""
        self.tempMetrics = nil
        
        // Randomize gyro on start to force alignment
        self.gyroRoll = Double.random(in: -12.0...12.0)
        self.gyroPitch = Double.random(in: -12.0...12.0)
    }
    
    /// Simulates leveling/aligning the camera.
    func alignStabilizer() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            gyroRoll = 0.0
            gyroPitch = 0.0
        }
    }
    
    /// Toggle Zoom Level
    func toggleZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            cameraZoom = (cameraZoom == 1.0) ? 2.0 : 1.0
        }
    }
    
    /// Trigger Simulated Shutter and begin Core ML process
    func capturePhoto() {
        guard let activeGuide = activeGuide else { return }
        
        // Shutter flash effect
        isCameraShutterFlashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.isCameraShutterFlashing = false
            self.runCoreMLAnalysis()
        }
    }
    
    /// Accept simulated Core ML report and save the capture progress
    func approvePhoto() {
        guard var vehicle = selectedVehicle,
              let guide = activeGuide,
              let metrics = tempMetrics else { return }
        
        // Update the guide in the current vehicle instance
        if let index = vehicle.guides.firstIndex(where: { $0.id == guide.id }) {
            vehicle.guides[index].status = .captured
            vehicle.guides[index].qualityMetrics = metrics
            // Assign a random mockup visual index for our generated vector illustrations
            vehicle.guides[index].capturedImageIndex = (activeGuide?.capturedImageIndex ?? index) + 1
            vehicle.guides[index].isSynced = false // Saved locally (offline), needs upload
        }
        
        // Update selected vehicle and list
        self.selectedVehicle = vehicle
        if let vIndex = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[vIndex] = vehicle
        }
        
        // Save updated inventory locally
        LocalStorageManager.saveVehicles(vehicles)
        
        // Close camera and analytics screens
        withAnimation {
            self.isCameraActive = false
            self.showQualityReport = false
            self.activeGuide = nil
        }
        
        // Automatically check if there's another pending guide to recommend
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let nextPending = vehicle.guides.first(where: { $0.status == .pending }) {
                // We can guide them to the next photo
                print("Suggested next photo: \(nextPending.name)")
            }
        }
    }
    
    /// Reject analysis and return to camera viewfinder
    func retakePhoto() {
        withAnimation {
            self.showQualityReport = false
            self.isAnalyzing = false
            self.analysisProgress = 0.0
            self.tempMetrics = nil
            // Slightly offset gyro again so they re-stabilize
            self.gyroRoll = Double.random(in: -8.0...8.0)
            self.gyroPitch = Double.random(in: -8.0...8.0)
        }
    }
    
    /// Close the capture overlay altogether
    func cancelCapture() {
        withAnimation {
            self.isCameraActive = false
            self.showQualityReport = false
            self.activeGuide = nil
        }
    }
    
    /// Add a brand new vehicle to inventory
    func addNewVehicle(year: Int, make: String, model: String, trim: String, color: String, colorHex: String) {
        let newVehicle = Vehicle(
            vin: generateMockVIN(),
            year: year,
            make: make,
            model: model,
            trim: trim,
            colorName: color,
            colorHex: colorHex,
            thumbnailSymbol: "car.fill",
            guides: [
                CaptureGuide(name: "Front Left 3/4 Angle", description: "Capture from 45° angle. Center the bumper in the horizontal guidelines.", symbolName: "car.side.front.open.passenger.side", status: .pending),
                CaptureGuide(name: "Front Profile", description: "Position straight-on. Keep headlight alignment symmetrical.", symbolName: "car.fill", status: .pending),
                CaptureGuide(name: "Side Profile", description: "Capture the full passenger profile. Keep horizon line level.", symbolName: "car.side.fill", status: .pending),
                CaptureGuide(name: "Rear 3/4 Angle", description: "Capture from rear 45° angle. Center the taillights inside grid.", symbolName: "car.side.rear.fill", status: .pending),
                CaptureGuide(name: "Odometer & Instrument Cluster", description: "Focus on the speedometer and record current odometer reading.", symbolName: "gauge.with.needle", status: .pending)
            ]
        )
        vehicles.insert(newVehicle, at: 0)
        
        // Save inventory changes to local disk storage
        LocalStorageManager.saveVehicles(vehicles)
    }
    
    // MARK: - Private Helper Methods
    
    private func seedInitialVehicles() {
        vehicles = [
            Vehicle(
                vin: "1G6AD5GX0H0194827",
                year: 2024,
                make: "Apex",
                model: "Aero EV",
                trim: "Performance AWD",
                colorName: "Midnight Cobalt Blue",
                colorHex: "#1E3C72",
                thumbnailSymbol: "sportscartimes",
                guides: [
                    CaptureGuide(name: "Front Left 3/4 Angle", description: "Capture from 45° angle. Center the bumper in the horizontal guidelines.", symbolName: "car.side.front.open.passenger.side", status: .captured, capturedImageIndex: 1, qualityMetrics: QualityMetrics(blurScore: 0.08, brightnessScore: 0.52, alignmentScore: 0.94, backgroundClass: "Clean Dealership")),
                    CaptureGuide(name: "Front Profile", description: "Position straight-on. Keep headlight alignment symmetrical.", symbolName: "car.fill", status: .captured, capturedImageIndex: 2, qualityMetrics: QualityMetrics(blurScore: 0.12, brightnessScore: 0.61, alignmentScore: 0.88, backgroundClass: "Clean Dealership")),
                    CaptureGuide(name: "Side Profile", description: "Capture the full passenger profile. Keep horizon line level.", symbolName: "car.side.fill", status: .pending),
                    CaptureGuide(name: "Rear 3/4 Angle", description: "Capture from rear 45° angle. Center the taillights inside grid.", symbolName: "car.side.rear.fill", status: .pending),
                    CaptureGuide(name: "Odometer & Instrument Cluster", description: "Focus on the speedometer and record current odometer reading.", symbolName: "gauge.with.needle", status: .pending)
                ]
            ),
            Vehicle(
                vin: "5YJ3E1EA5KF028345",
                year: 2023,
                make: "Tesla",
                model: "Model 3",
                trim: "Long Range",
                colorName: "Ultra Red",
                colorHex: "#8B0000",
                thumbnailSymbol: "car.fill",
                guides: [
                    CaptureGuide(name: "Front Left 3/4 Angle", description: "Capture from 45° angle. Center the bumper in the horizontal guidelines.", symbolName: "car.side.front.open.passenger.side", status: .pending),
                    CaptureGuide(name: "Front Profile", description: "Position straight-on. Keep headlight alignment symmetrical.", symbolName: "car.fill", status: .pending),
                    CaptureGuide(name: "Side Profile", description: "Capture the full passenger profile. Keep horizon line level.", symbolName: "car.side.fill", status: .pending),
                    CaptureGuide(name: "Rear 3/4 Angle", description: "Capture from rear 45° angle. Center the taillights inside grid.", symbolName: "car.side.rear.fill", status: .pending),
                    CaptureGuide(name: "Odometer & Instrument Cluster", description: "Focus on the speedometer and record current odometer reading.", symbolName: "gauge.with.needle", status: .pending)
                ]
            ),
            Vehicle(
                vin: "1FTFW1ED1PK123490",
                year: 2024,
                make: "Ford",
                model: "F-150 Lightning",
                trim: "Lariat",
                colorName: "Carbonized Gray",
                colorHex: "#4F5D65",
                thumbnailSymbol: "suv.fill",
                guides: [
                    CaptureGuide(name: "Front Left 3/4 Angle", description: "Capture from 45° angle. Center the bumper in the horizontal guidelines.", symbolName: "car.side.front.open.passenger.side", status: .captured, capturedImageIndex: 1, qualityMetrics: QualityMetrics(blurScore: 0.05, brightnessScore: 0.49, alignmentScore: 0.95, backgroundClass: "Clean Lot")),
                    CaptureGuide(name: "Front Profile", description: "Position straight-on. Keep headlight alignment symmetrical.", symbolName: "car.fill", status: .captured, capturedImageIndex: 2, qualityMetrics: QualityMetrics(blurScore: 0.15, brightnessScore: 0.55, alignmentScore: 0.82, backgroundClass: "Clean Lot")),
                    CaptureGuide(name: "Side Profile", description: "Capture the full passenger profile. Keep horizon line level.", symbolName: "car.side.fill", status: .captured, capturedImageIndex: 3, qualityMetrics: QualityMetrics(blurScore: 0.10, brightnessScore: 0.60, alignmentScore: 0.89, backgroundClass: "Clean Lot")),
                    CaptureGuide(name: "Rear 3/4 Angle", description: "Capture from rear 45° angle. Center the taillights inside grid.", symbolName: "car.side.rear.fill", status: .captured, capturedImageIndex: 4, qualityMetrics: QualityMetrics(blurScore: 0.09, brightnessScore: 0.51, alignmentScore: 0.91, backgroundClass: "Clean Lot")),
                    CaptureGuide(name: "Odometer & Instrument Cluster", description: "Focus on the speedometer and record current odometer reading.", symbolName: "gauge.with.needle", status: .captured, capturedImageIndex: 5, qualityMetrics: QualityMetrics(blurScore: 0.04, brightnessScore: 0.65, alignmentScore: 0.98, backgroundClass: "Clean Lot"))
                ]
            )
        ]
        selectedVehicle = vehicles.first
    }
    
    private func startSimulatingGyroDrift() {
        gyroTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isCameraActive, !self.isAnalyzing, !self.showQualityReport else { return }
            
            // Apply slight random walk to gyro drift
            let rollChange = Double.random(in: -0.8...0.8)
            let pitchChange = Double.random(in: -0.8...0.8)
            
            // If they are close, don't drift away too aggressively to let them stabilize
            let attractionFactor = 0.05
            self.gyroRoll += rollChange - (self.gyroRoll * attractionFactor)
            self.gyroPitch += pitchChange - (self.gyroPitch * attractionFactor)
            
            // Constrain
            self.gyroRoll = max(-15.0, min(15.0, self.gyroRoll))
            self.gyroPitch = max(-15.0, min(15.0, self.gyroPitch))
        }
    }
    
    private func runCoreMLAnalysis() {
        isAnalyzing = true
        analysisProgress = 0.0
        analysisStepMessage = "Initializing Core ML camera frame pipeline..."
        
        let steps = [
            (0.2, "Feeding frame to MobileNetV4 convolutional layer..."),
            (0.4, "Segmenting vehicle contour boundaries..."),
            (0.6, "Analyzing contrast and edge high-frequencies (blur score)..."),
            (0.8, "Running scene classifier on background surroundings..."),
            (1.0, "Core ML inference completed successfully.")
        ]
        
        var stepIndex = 0
        
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if stepIndex < steps.count {
                let currentStep = steps[stepIndex]
                withAnimation(.linear(duration: 0.4)) {
                    self.analysisProgress = currentStep.0
                }
                self.analysisStepMessage = currentStep.1
                stepIndex += 1
            } else {
                timer.invalidate()
                self.generateMockAnalysisResults()
            }
        }
    }
    
    private func generateMockAnalysisResults() {
        // Base quality metrics on how aligned they were during capture
        let alignmentFactor = 1.0 - (min(15.0, abs(gyroRoll) + abs(gyroPitch)) / 30.0)
        let alignment = max(0.4, min(1.0, alignmentFactor + Double.random(in: -0.05...0.05)))
        
        // Randomize blur/brightness unless highly unaligned (which adds blur)
        let extraBlur = (1.0 - alignment) * 0.25
        let blur = max(0.02, min(0.99, Double.random(in: 0.03...0.18) + extraBlur))
        let brightness = Double.random(in: 0.42...0.68)
        
        // Background classification
        let bgClasses = ["Clean Dealership", "Clean Lot", "Messy Lot", "High Contrast / Sun Glare"]
        // Highly aligned captures usually get clean background settings
        let bgClass = (alignment > 0.75) ? bgClasses[Int.random(in: 0...1)] : bgClasses[Int.random(in: 0...3)]
        
        self.tempMetrics = QualityMetrics(
            blurScore: blur,
            brightnessScore: brightness,
            alignmentScore: alignment,
            backgroundClass: bgClass
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isAnalyzing = false
            self.showQualityReport = true
        }
    }
    
    private func generateMockVIN() -> String {
        let characters = "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
        var vin = ""
        for _ in 0..<17 {
            if let randomChar = characters.randomElement() {
                vin.append(randomChar)
            }
        }
        return vin
    }
    
    /// Synchronizes all offline captured photos to the cloud server
    func syncOfflineCaptures() {
        var unsyncedItems: [(vehicleIndex: Int, guideIndex: Int, name: String)] = []
        for vIdx in 0..<vehicles.count {
            for gIdx in 0..<vehicles[vIdx].guides.count {
                if vehicles[vIdx].guides[gIdx].status == .captured && !vehicles[vIdx].guides[gIdx].isSynced {
                    unsyncedItems.append((vIdx, gIdx, "\(vehicles[vIdx].year) \(vehicles[vIdx].model) - \(vehicles[vIdx].guides[gIdx].name)"))
                }
            }
        }
        
        guard !unsyncedItems.isEmpty else { return }
        
        isSyncing = true
        syncProgress = 0.0
        syncMessage = "Establishing connection to automotive cloud server..."
        
        var itemIndex = 0
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if itemIndex < unsyncedItems.count {
                let item = unsyncedItems[itemIndex]
                self.syncMessage = "Uploading: \(item.name)..."
                
                withAnimation {
                    self.syncProgress = Double(itemIndex + 1) / Double(unsyncedItems.count)
                }
                
                // Update local array model state
                self.vehicles[item.vehicleIndex].guides[item.guideIndex].isSynced = true
                
                // Mirror changes on active screen bindings
                if self.selectedVehicle?.id == self.vehicles[item.vehicleIndex].id {
                    self.selectedVehicle = self.vehicles[item.vehicleIndex]
                }
                
                itemIndex += 1
            } else {
                timer.invalidate()
                self.syncMessage = "Sync completed! All database records updated."
                
                // Save updated array locally
                LocalStorageManager.saveVehicles(self.vehicles)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        self.isSyncing = false
                    }
                }
            }
        }
    }
}
