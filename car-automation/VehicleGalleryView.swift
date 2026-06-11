//
//  VehicleGalleryView.swift
//  car-automation
//
//  Created by Monzurul Ehsan on 6/11/26.
//

import SwiftUI

struct VehicleGalleryView: View {
    @ObservedObject var viewModel: CaptureViewModel
    var vehicle: Vehicle
    
    @Environment(\.presentationMode) var presentationMode
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header vehicle card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(String(vehicle.year))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                        
                        Spacer()
                        
                        Text("VIN: \(vehicle.vin)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text("\(vehicle.make) \(vehicle.model)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Text(vehicle.trim)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))
                    
                    HStack {
                        Circle()
                            .fill(Color(hex: vehicle.colorHex))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        
                        Text(vehicle.colorName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 4)
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                        .padding(.vertical, 8)
                    
                    // Merchandising Progress Details
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Capture Completion")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(vehicle.captureStatusText)
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(vehicle.progress == 1.0 ? .green : .white)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 4)
                                .frame(width: 48, height: 48)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(vehicle.progress))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.cyan, .green]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 48, height: 48)
                                .rotationEffect(.degrees(-90))
                            
                            Text(String(format: "%.0f%%", vehicle.progress * 100))
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal)
                
                // Photo checklist guide list
                VStack(alignment: .leading, spacing: 16) {
                    Text("Capture Guide List")
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(vehicle.guides) { guide in
                            GuideGridItemView(guide: guide, vehicleColorHex: vehicle.colorHex) {
                                viewModel.startCapture(for: guide)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(
            Color(hex: "#09090b")
                .ignoresSafeArea()
        )
        .navigationTitle("Vehicle Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

struct GuideGridItemView: View {
    var guide: CaptureGuide
    var vehicleColorHex: String
    var onCaptureTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if guide.status == .captured {
                // Mock visual representation of the captured car from that perspective
                MockCapturedVehicleThumbnail(guideName: guide.name, colorHex: vehicleColorHex)
                    .frame(height: 110)
                    .clipped()
            } else {
                // Placeholder pending container
                VStack(spacing: 8) {
                    Image(systemName: guide.symbolName)
                        .font(.title)
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("No Photo")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(guide.name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if guide.status == .captured {
                        Image(systemName: guide.isSynced ? "cloud.checkmark.fill" : "icloud.and.arrow.up.fill")
                            .font(.system(size: 10))
                            .foregroundColor(guide.isSynced ? .green : .cyan)
                        
                        Text(guide.isSynced ? "Synced" : "Offline")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(guide.isSynced ? .green : .cyan)
                    } else {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        
                        Text(guide.status.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    if guide.status == .captured, let metrics = guide.qualityMetrics {
                        Text(String(format: "Score: %d%%", Int(metrics.alignmentScore * 100)))
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                if guide.status == .pending {
                    Button(action: onCaptureTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10))
                            Text("Capture")
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.cyan)
                        .cornerRadius(8)
                    }
                    .padding(.top, 4)
                } else {
                    Button(action: onCaptureTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 9))
                            Text("Retake")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(guide.status == .captured ? Color.green.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
}

/// Dynamic mockup illustration generation for captured vehicles
struct MockCapturedVehicleThumbnail: View {
    var guideName: String
    var colorHex: String
    
    var body: some View {
        ZStack {
            // Background studio gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1e1e24"),
                    Color(hex: "#101012")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Grid floor guide lines
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.15), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 35)
            }
            
            // Draw vector vehicle corresponding to the angle
            if guideName.contains("Front Left") {
                // Angled Front Left filled silhouette
                Path { path in
                    path.move(to: CGPoint(x: 35, y: 75))
                    path.addLine(to: CGPoint(x: 55, y: 45))
                    path.addLine(to: CGPoint(x: 105, y: 45))
                    path.addLine(to: CGPoint(x: 120, y: 70))
                    path.addLine(to: CGPoint(x: 135, y: 72))
                    path.addLine(to: CGPoint(x: 130, y: 92))
                    path.addLine(to: CGPoint(x: 25, y: 90))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: colorHex), Color(hex: colorHex).opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Headlight overlay
                Path { path in
                    path.addEllipse(in: CGRect(x: 110, y: 76, width: 12, height: 6))
                }
                .fill(Color.yellow.opacity(0.95))
                .shadow(color: .yellow, radius: 2)
                
            } else if guideName.contains("Front Profile") {
                // Direct front vector
                VStack(spacing: 0) {
                    // Cabin
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: colorHex).opacity(0.8))
                        .frame(width: 60, height: 26)
                        
                    // Body/Hood
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: colorHex))
                        .frame(width: 85, height: 24)
                        .offset(y: -4)
                        .overlay(
                            HStack {
                                Circle().fill(Color.yellow).frame(width: 8, height: 8)
                                Spacer()
                                Circle().fill(Color.yellow).frame(width: 8, height: 8)
                            }
                            .padding(.horizontal, 8)
                            .offset(y: -2)
                        )
                }
                
            } else if guideName.contains("Side Profile") {
                // Sleek side profile vector
                Path { path in
                    path.move(to: CGPoint(x: 20, y: 75))
                    path.addLine(to: CGPoint(x: 45, y: 70))
                    path.addLine(to: CGPoint(x: 65, y: 45))
                    path.addLine(to: CGPoint(x: 110, y: 45))
                    path.addLine(to: CGPoint(x: 125, y: 70))
                    path.addLine(to: CGPoint(x: 145, y: 75))
                    path.addLine(to: CGPoint(x: 145, y: 90))
                    path.addLine(to: CGPoint(x: 20, y: 90))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: colorHex), Color(hex: colorHex).opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Wheel cutouts
                HStack(spacing: 50) {
                    Circle().fill(Color.black).frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                    Circle().fill(Color.black).frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                }
                .offset(y: 20)
                
            } else if guideName.contains("Rear") {
                // Direct rear vector
                VStack(spacing: 0) {
                    // Cabin/Windshield
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: colorHex).opacity(0.7))
                        .frame(width: 58, height: 26)
                        .overlay(
                            Rectangle()
                                .fill(Color.black.opacity(0.8))
                                .frame(height: 12)
                                .offset(y: 2)
                        )
                        
                    // Boot / Bumper
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: colorHex))
                        .frame(width: 85, height: 24)
                        .offset(y: -4)
                        .overlay(
                            HStack {
                                Rectangle().fill(Color.red).frame(width: 16, height: 5)
                                Spacer()
                                Rectangle().fill(Color.red).frame(width: 16, height: 5)
                            }
                            .padding(.horizontal, 8)
                            .offset(y: -2)
                        )
                }
                
            } else {
                // Dash Odometer readout
                VStack(spacing: 4) {
                    Image(systemName: "gauge.with.needle.fill")
                        .font(.title3)
                        .foregroundColor(.green.opacity(0.8))
                    
                    Text("012480 mi")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(4)
                }
            }
            
            // "Core ML Audited" badge in top-left
            VStack {
                HStack {
                    Text("AI AUDITED")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(3)
                        .padding(6)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
