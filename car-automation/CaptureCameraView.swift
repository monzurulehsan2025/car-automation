//
//  CaptureCameraView.swift
//  car-automation
//
//  Created by Monzurul Ehsan on 6/11/26.
//

import SwiftUI

struct CaptureCameraView: View {
    @ObservedObject var viewModel: CaptureViewModel
    
    var body: some View {
        ZStack {
            // Viewfinder Dark Background
            Color.black.ignoresSafeArea()
            
            // Viewfinder Simulator
            VStack(spacing: 0) {
                // Top control bar
                HStack {
                    Button(action: {
                        viewModel.cancelCapture()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(viewModel.activeGuide?.name ?? "Capture")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.isFlashOn.toggle()
                    }) {
                        Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.isFlashOn ? .yellow : .white.opacity(0.8))
                            .padding()
                    }
                }
                .background(Color.black.opacity(0.7))
                
                // Viewfinder Content Area
                ZStack {
                    // Mock Live Feed / Camera Texture
                    ViewfinderFeedBackground(zoom: viewModel.cameraZoom, vehicleColorHex: viewModel.selectedVehicle?.colorHex ?? "#1E3C72")
                    
                    // Grid Lines
                    ViewfinderGrid()
                    
                    // Vehicle Silhouette Guide Overlay
                    if let guide = viewModel.activeGuide {
                        SilhouetteOverlay(guideName: guide.name, isStabilized: viewModel.isStabilized)
                            .padding(40)
                    }
                    
                    // 3D Level / Gyro Stabilizer Indicator
                    LevelStabilizerView(roll: viewModel.gyroRoll, pitch: viewModel.gyroPitch)
                    
                    // Camera Shutter Flash Effect
                    if viewModel.isCameraShutterFlashing {
                        Color.white
                            .transition(.opacity)
                    }
                    
                    // CoreML Progress / Scanning overlay
                    if viewModel.isAnalyzing {
                        AIQualityCheckView(viewModel: viewModel)
                    }
                }
                .aspectRatio(3/4, contentMode: .fit)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(viewModel.isStabilized ? Color.green.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 2)
                )
                
                // Bottom control panel
                VStack(spacing: 20) {
                    // Instruction Banner
                    Text(viewModel.isStabilized ? "Perfect! Hold still and capture." : "Align stabilizer & fit vehicle inside guidelines.")
                        .font(.subheadline)
                        .foregroundColor(viewModel.isStabilized ? .green : .white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.isStabilized ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                        )
                        .animation(.easeInOut, value: viewModel.isStabilized)
                        .padding(.top, 12)
                    
                    HStack(spacing: 40) {
                        // Zoom toggle (1x / 2x)
                        Button(action: {
                            viewModel.toggleZoom()
                        }) {
                            Text(viewModel.cameraZoom == 1.0 ? "1x" : "2x")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                        
                        // Shutter Button
                        Button(action: {
                            viewModel.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .stroke(viewModel.isStabilized ? Color.green : Color.white, lineWidth: 3)
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(viewModel.isStabilized ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isStabilized)
                            }
                        }
                        .disabled(viewModel.isAnalyzing)
                        
                        // Alignment Simulation Helper
                        Button(action: {
                            viewModel.alignStabilizer()
                        }) {
                            Image(systemName: "gyroscope")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(viewModel.isStabilized ? Color.green.opacity(0.3) : Color.white.opacity(0.15)))
                        }
                    }
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)
            }
        }
    }
}

// MARK: - Subviews

/// Viewfinder background simulating a dealership scene or vehicle
struct ViewfinderFeedBackground: View {
    var zoom: CGFloat
    var vehicleColorHex: String
    
    var body: some View {
        ZStack {
            // Outdoor car lot gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#2c3e50"),
                    Color(hex: "#bdc3c7"),
                    Color(hex: "#7f8c8d")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Ground Grid Reflection
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(height: 120)
                    .blur(radius: 10)
            }
            
            // Mock Vehicle Shadow / Background
            Circle()
                .fill(Color(hex: vehicleColorHex).opacity(0.85))
                .frame(width: 180 * zoom, height: 140 * zoom)
                .scaleEffect(x: 2.2, y: 0.6)
                .offset(y: 20)
                .blur(radius: 25)
            
            // Simulated Car Body Shape
            Image(systemName: "car.side.fill")
                .font(.system(size: 140))
                .foregroundColor(Color(hex: vehicleColorHex))
                .scaleEffect(zoom)
                .opacity(0.4)
                .blur(radius: 2)
            
            // Camera aperture/sensor particle lines
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
            }
        }
    }
}

/// Custom classic photography grid lines
struct ViewfinderGrid: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                // Vertical lines
                let w = geo.size.width
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: geo.size.height))
                
                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: geo.size.height))
                
                // Horizontal lines
                let h = geo.size.height
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                
                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
            }
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
    }
}

/// Live gyro bubble level indicator
struct LevelStabilizerView: View {
    var roll: Double
    var pitch: Double
    
    var body: some View {
        ZStack {
            // Target Reticle (Outer Ring)
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                .frame(width: 44, height: 44)
            
            // Inner Target
            Circle()
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                .frame(width: 16, height: 16)
            
            // Vertical & Horizontal crosshair ticks
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 60, height: 1)
            
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 1, height: 60)
            
            // Simulated Gyro Bubble (Moves dynamically)
            Circle()
                .fill(isAligned ? Color.green : Color.yellow)
                .frame(width: 12, height: 12)
                .offset(
                    x: CGFloat(roll * 2.5),
                    y: CGFloat(pitch * 2.5)
                )
                .shadow(color: isAligned ? .green : .yellow, radius: 4)
                .animation(.easeOut(duration: 0.1), value: roll)
        }
        .frame(width: 80, height: 80)
        .background(
            Circle()
                .fill(Color.black.opacity(0.45))
        )
    }
    
    private var isAligned: Bool {
        abs(roll) < 1.0 && abs(pitch) < 1.0
    }
}

/// Dynamic silhouette outlines for photography guidelines
struct SilhouetteOverlay: View {
    var guideName: String
    var isStabilized: Bool
    
    var body: some View {
        let activeColor = isStabilized ? Color.green : Color.white.opacity(0.85)
        
        ZStack {
            if guideName.contains("Front Left") {
                // Front Left 3/4 perspective guide wireframe
                Path { path in
                    // Windshield
                    path.move(to: CGPoint(x: 100, y: 60))
                    path.addLine(to: CGPoint(x: 180, y: 60))
                    path.addLine(to: CGPoint(x: 210, y: 110))
                    path.addLine(to: CGPoint(x: 80, y: 110))
                    path.closeSubpath()
                    
                    // Hood
                    path.move(to: CGPoint(x: 80, y: 110))
                    path.addLine(to: CGPoint(x: 210, y: 110))
                    path.addLine(to: CGPoint(x: 230, y: 155))
                    path.addLine(to: CGPoint(x: 60, y: 155))
                    path.closeSubpath()
                    
                    // Bumper and front grille outline
                    path.move(to: CGPoint(x: 60, y: 155))
                    path.addLine(to: CGPoint(x: 230, y: 155))
                    path.addLine(to: CGPoint(x: 220, y: 195))
                    path.addLine(to: CGPoint(x: 70, y: 195))
                    path.closeSubpath()
                    
                    // Side cab
                    path.move(to: CGPoint(x: 80, y: 110))
                    path.addLine(to: CGPoint(x: 30, y: 115))
                    path.addLine(to: CGPoint(x: 45, y: 68))
                    path.addLine(to: CGPoint(x: 100, y: 60))
                }
                .stroke(activeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
            } else if guideName.contains("Front Profile") {
                // Symmetrical front-on layout
                Path { path in
                    // Roof & Windshield
                    path.move(to: CGPoint(x: 70, y: 60))
                    path.addLine(to: CGPoint(x: 210, y: 60))
                    path.addLine(to: CGPoint(x: 240, y: 115))
                    path.addLine(to: CGPoint(x: 40, y: 115))
                    path.closeSubpath()
                    
                    // Body/Hood
                    path.move(to: CGPoint(x: 40, y: 115))
                    path.addLine(to: CGPoint(x: 240, y: 115))
                    path.addLine(to: CGPoint(x: 250, y: 170))
                    path.addLine(to: CGPoint(x: 30, y: 170))
                    path.closeSubpath()
                    
                    // Lower bumper/grille
                    path.move(to: CGPoint(x: 30, y: 170))
                    path.addLine(to: CGPoint(x: 250, y: 170))
                    path.addLine(to: CGPoint(x: 240, y: 205))
                    path.addLine(to: CGPoint(x: 40, y: 205))
                    path.closeSubpath()
                    
                    // Left Headlight
                    path.addRoundedRect(in: CGRect(x: 50, y: 125, width: 35, height: 18), cornerSize: CGSize(width: 4, height: 4))
                    
                    // Right Headlight
                    path.addRoundedRect(in: CGRect(x: 195, y: 125, width: 35, height: 18), cornerSize: CGSize(width: 4, height: 4))
                }
                .stroke(activeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
            } else if guideName.contains("Side Profile") {
                // Full side car wireframe outline
                Path { path in
                    // Left wheel hub
                    path.addArc(center: CGPoint(x: 75, y: 180), radius: 24, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: true)
                    
                    // Right wheel hub
                    path.addArc(center: CGPoint(x: 205, y: 180), radius: 24, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: true)
                }
                .stroke(activeColor, lineWidth: 2)
                
                Path { path in
                    // Front bumper
                    path.move(to: CGPoint(x: 20, y: 180))
                    path.addLine(to: CGPoint(x: 25, y: 145))
                    // Hood
                    path.addLine(to: CGPoint(x: 65, y: 135))
                    // Windshield
                    path.addLine(to: CGPoint(x: 110, y: 80))
                    // Roof line
                    path.addLine(to: CGPoint(x: 185, y: 80))
                    // Rear windshield
                    path.addLine(to: CGPoint(x: 225, y: 125))
                    // Trunk
                    path.addLine(to: CGPoint(x: 255, y: 130))
                    // Rear bumper
                    path.addLine(to: CGPoint(x: 260, y: 180))
                    
                    // Underbody connecting wheels
                    path.addLine(to: CGPoint(x: 229, y: 180))
                    path.move(to: CGPoint(x: 181, y: 180))
                    path.addLine(to: CGPoint(x: 99, y: 180))
                    path.move(to: CGPoint(x: 51, y: 180))
                    path.addLine(to: CGPoint(x: 20, y: 180))
                }
                .stroke(activeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
            } else if guideName.contains("Rear") {
                // Back silhouette
                Path { path in
                    // Rear roof and glass
                    path.move(to: CGPoint(x: 80, y: 65))
                    path.addLine(to: CGPoint(x: 200, y: 65))
                    path.addLine(to: CGPoint(x: 235, y: 120))
                    path.addLine(to: CGPoint(x: 45, y: 120))
                    path.closeSubpath()
                    
                    // Trunk panel
                    path.move(to: CGPoint(x: 45, y: 120))
                    path.addLine(to: CGPoint(x: 235, y: 120))
                    path.addLine(to: CGPoint(x: 245, y: 175))
                    path.addLine(to: CGPoint(x: 35, y: 175))
                    path.closeSubpath()
                    
                    // Tail lights
                    path.addRoundedRect(in: CGRect(x: 50, y: 128, width: 40, height: 15), cornerSize: CGSize(width: 3, height: 3))
                    path.addRoundedRect(in: CGRect(x: 190, y: 128, width: 40, height: 15), cornerSize: CGSize(width: 3, height: 3))
                    
                    // License plate slot
                    path.addRect(CGRect(x: 110, y: 142, width: 60, height: 20))
                }
                .stroke(activeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
            } else {
                // Instrument cluster / gauge design for dashboard/odometer
                ZStack {
                    // Gauge Semi-circle
                    Circle()
                        .trim(from: 0.15, to: 0.85)
                        .stroke(activeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [4, 6]))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(90))
                    
                    // Dial needle
                    Path { path in
                        path.move(to: CGPoint(x: 75, y: 75))
                        path.addLine(to: CGPoint(x: 40, y: 35))
                    }
                    .stroke(Color.red.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 150, height: 150)
                    
                    Text("ODOMETER GUIDE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(activeColor)
                        .offset(y: 40)
                }
            }
        }
    }
}

// MARK: - Hex Color Extension Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
