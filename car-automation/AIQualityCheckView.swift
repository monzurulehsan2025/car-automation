//
//  AIQualityCheckView.swift
//  car-automation
//
//  Created by Monzurul Ehsan on 6/11/26.
//

import SwiftUI

struct AIQualityCheckView: View {
    @ObservedObject var viewModel: CaptureViewModel
    
    // Controls the scanner laser animation
    @State private var laserOffset: CGFloat = -150
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dimmed translucent backing
                Color.black.opacity(0.85)
                
                if viewModel.isAnalyzing {
                    // Scanning state
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Icon & Scanning box
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Image(systemName: "cpu.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.green)
                                        .shadow(color: .green, radius: 10)
                                )
                            
                            // Laser Line Animation
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .green, .clear]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 4)
                                .offset(y: laserOffset)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                        laserOffset = 70
                                    }
                                }
                        }
                        
                        Text("Core ML Quality Audit")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Diagnostic Log Screen
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.analysisStepMessage)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(viewModel.analysisStepMessage)
                                .transition(.opacity)
                            
                            // Visual progress bar
                            ProgressView(value: viewModel.analysisProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .scaleEffect(y: 1.5, anchor: .center)
                                .padding(.top, 4)
                        }
                        .padding()
                        .frame(width: geo.size.width - 60)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        
                        Spacer()
                    }
                } else if viewModel.showQualityReport, let metrics = viewModel.tempMetrics {
                    // Quality report card sheet
                    ScrollView {
                        VStack(spacing: 20) {
                            // Status Header
                            VStack(spacing: 8) {
                                Image(systemName: metrics.isApproved ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(metrics.isApproved ? .green : .orange)
                                    .shadow(color: metrics.isApproved ? .green : .orange, radius: 8)
                                
                                Text(metrics.isApproved ? "AI QUALITY PASSED" : "QUALITY WARNING")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                
                                Text(metrics.isApproved ? "Vehicle photo meets all merchandising standards." : "Photo is substandard. Please review warnings below.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 20)
                            
                            // Audit list items
                            VStack(spacing: 12) {
                                // 1. Blur
                                MetricRowView(
                                    title: "Image Sharpness",
                                    valueText: String(format: "Blur Index: %.3f", metrics.blurScore),
                                    idealText: "Ideal: < 0.250",
                                    isPassed: metrics.isBlurApproved,
                                    errorReason: "Camera shake or refocus issue detected."
                                )
                                
                                // 2. Brightness
                                MetricRowView(
                                    title: "Lighting & Exposure",
                                    valueText: String(format: "Exposure: %.2f", metrics.brightnessScore),
                                    idealText: "Ideal: 0.35 - 0.75",
                                    isPassed: metrics.isBrightnessApproved,
                                    errorReason: metrics.brightnessScore < 0.35 ? "Too dark. Turn on flash or relocate." : "Sun glare/overexposure detected."
                                )
                                
                                // 3. Alignment
                                MetricRowView(
                                    title: "Grid Framing Alignment",
                                    valueText: String(format: "Match Index: %d%%", Int(metrics.alignmentScore * 100)),
                                    idealText: "Ideal: > 70%",
                                    isPassed: metrics.isAlignmentApproved,
                                    errorReason: "Car outlines misaligned with wireframe template."
                                )
                                
                                // 4. Background Surrounding
                                MetricRowView(
                                    title: "Background Classifier",
                                    valueText: metrics.backgroundClass,
                                    idealText: "Ideal: Clean Dealership/Lot",
                                    isPassed: metrics.isBackgroundApproved,
                                    errorReason: "Background messy or contains competing objects."
                                )
                            }
                            .padding(.horizontal)
                            
                            // Buttons
                            VStack(spacing: 12) {
                                if metrics.isApproved {
                                    Button(action: {
                                        viewModel.approvePhoto()
                                    }) {
                                        Text("Save & Complete Shot")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .cornerRadius(12)
                                            .shadow(color: .green.opacity(0.4), radius: 5)
                                    }
                                } else {
                                    Button(action: {
                                        viewModel.retakePhoto()
                                    }) {
                                        Text("Retake Photo")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.yellow)
                                            .cornerRadius(12)
                                            .shadow(color: .yellow.opacity(0.4), radius: 5)
                                    }
                                    
                                    Button(action: {
                                        viewModel.approvePhoto() // Manual Override
                                    }) {
                                        Text("Override & Use Anyway")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                            .underline()
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                }
                                
                                Button(action: {
                                    viewModel.retakePhoto()
                                }) {
                                    Text("Discard & Go Back")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.vertical, 4)
                                }
                                .visible(if: metrics.isApproved)
                            }
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#121214").opacity(0.95))
                    .cornerRadius(20)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(metrics.isApproved ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1.5)
                            .padding()
                    )
                }
            }
        }
    }
}

// MARK: - Row Helper

struct MetricRowView: View {
    var title: String
    var valueText: String
    var idealText: String
    var isPassed: Bool
    var errorReason: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Audit Metric Indicator
                Image(systemName: isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isPassed ? .green : .red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(valueText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(isPassed ? .green : .orange)
                }
                
                Spacer()
                
                Text(idealText)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            
            if !isPassed {
                Text(errorReason)
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.8))
                    .padding(.leading, 28)
            }
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPassed ? Color.green.opacity(0.1) : Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Conditional Visibility Modifier Helper
extension View {
    @ViewBuilder
    func visible(if condition: Bool) -> some View {
        if condition {
            self
        } else {
            EmptyView()
        }
    }
}
