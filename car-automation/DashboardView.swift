//
//  DashboardView.swift
//  car-automation
//
//  Created by Monzurul Ehsan on 6/11/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel = CaptureViewModel()
    @State private var showingAddVehicleSheet = false
    
    // Form variables for adding vehicle
    @State private var inputYear = 2024
    @State private var inputMake = ""
    @State private var inputModel = ""
    @State private var inputTrim = ""
    @State private var selectedColorIndex = 0
    
    private let colorsPreset = [
        (name: "Quantum Silver", hex: "#7f8c8d"),
        (name: "Volcanic Red", hex: "#c0392b"),
        (name: "Deep Ocean Cobalt", hex: "#2980b9"),
        (name: "Obsidian Black", hex: "#1a1a1a"),
        (name: "Alpine Gloss White", hex: "#f1f2f6")
    ]
    
    private var unsyncedPhotosCount: Int {
        viewModel.vehicles.reduce(0) { sum, vehicle in
            sum + vehicle.guides.filter { $0.status == .captured && !$0.isSynced }.count
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Sync Banner
                    if unsyncedPhotosCount > 0 {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .font(.title3)
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Offline Captures Ready")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("\(unsyncedPhotosCount) photos captured offline pending server sync.")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.syncOfflineCaptures()
                                }
                            }) {
                                Text("Sync Now")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.cyan)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.cyan.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Dealership stats card
                    DealershipStatsOverview(vehicles: viewModel.vehicles)
                    
                    // Inventory list section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Dealership Inventory")
                                .font(.title3)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddVehicleSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Car")
                                        .fontWeight(.bold)
                                }
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.cyan)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        
                        // List of vehicles
                        if viewModel.vehicles.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "car.2.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("No vehicles in inventory")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.vehicles) { vehicle in
                                    NavigationLink(value: vehicle) {
                                        VehicleRowCard(vehicle: vehicle)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(
                Color(hex: "#09090b")
                    .ignoresSafeArea()
            )
            .navigationTitle("AutoCapture AI")
            .navigationDestination(for: Vehicle.self) { vehicle in
                // Bind our viewmodel so changes synchronise perfectly
                VehicleGalleryView(viewModel: viewModel, vehicle: viewModel.vehicles.first(where: { $0.id == vehicle.id }) ?? vehicle)
            }
            .sheet(isPresented: $showingAddVehicleSheet) {
                AddVehicleSheet(
                    year: $inputYear,
                    make: $inputMake,
                    model: $inputModel,
                    trim: $inputTrim,
                    colorIndex: $selectedColorIndex,
                    colors: colorsPreset,
                    onSave: {
                        viewModel.addNewVehicle(
                            year: inputYear,
                            make: inputMake,
                            model: inputModel,
                            trim: inputTrim,
                            color: colorsPreset[selectedColorIndex].name,
                            colorHex: colorsPreset[selectedColorIndex].hex
                        )
                        // Reset forms
                        inputMake = ""
                        inputModel = ""
                        inputTrim = ""
                        showingAddVehicleSheet = false
                    },
                    onDismiss: {
                        showingAddVehicleSheet = false
                    }
                )
            }
            // Launch viewfinder overlay when active
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.isCameraActive },
                set: { if !$0 { viewModel.cancelCapture() } }
            )) {
                CaptureCameraView(viewModel: viewModel)
            }
            .overlay {
                if viewModel.isSyncing {
                    SyncProgressOverlay(
                        progress: viewModel.syncProgress,
                        message: viewModel.syncMessage
                    )
                    .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - Sync Progress Overlay View

struct SyncProgressOverlay: View {
    var progress: Double
    var message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 6)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .green]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.title)
                        .foregroundColor(.cyan)
                }
                
                VStack(spacing: 8) {
                    Text("Syncing Offline Library")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                    .frame(width: 200)
            }
            .padding(32)
            .background(Color(hex: "#121214"))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(24)
        }
    }
}

// MARK: - Dealership stats block

struct DealershipStatsOverview: View {
    var vehicles: [Vehicle]
    
    var totalPhotosRequired: Int {
        vehicles.reduce(0) { $0 + $1.guides.count }
    }
    
    var totalPhotosCaptured: Int {
        vehicles.reduce(0) { sum, vehicle in
            sum + vehicle.guides.filter { $0.status == .captured }.count
        }
    }
    
    var completionRatio: Double {
        guard totalPhotosRequired > 0 else { return 0.0 }
        return Double(totalPhotosCaptured) / Double(totalPhotosRequired)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dealership Operations")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
                .tracking(1)
            
            HStack(spacing: 20) {
                // Completed Ring representation
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(completionRatio))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .green]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", completionRatio * 100))
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Text("Ready")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Details breakdown
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Inventory Count")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(vehicles.count) Units")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Captured Photos")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(totalPhotosCaptured) / \(totalPhotosRequired)")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Simple capsule progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.cyan)
                                .frame(width: geo.size.width * CGFloat(completionRatio), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Vehicle row card

struct VehicleRowCard: View {
    var vehicle: Vehicle
    
    var body: some View {
        HStack(spacing: 16) {
            // Visual symbol representing the vehicle type
            ZStack {
                Circle()
                    .fill(Color(hex: vehicle.colorHex).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: vehicle.thumbnailSymbol)
                    .font(.title3)
                    .foregroundColor(Color(hex: vehicle.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(String(vehicle.year)) \(vehicle.make) \(vehicle.model)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(vehicle.trim)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                // Visual progress bar
                HStack(spacing: 8) {
                    ProgressView(value: vehicle.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: vehicle.progress == 1.0 ? .green : .cyan))
                        .frame(width: 80)
                    
                    Text(String(format: "%.0f%%", vehicle.progress * 100))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(vehicle.progress == 1.0 ? .green : .white.opacity(0.6))
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Completion Status Tag
            VStack(alignment: .trailing, spacing: 6) {
                Text(vehicle.progress == 1.0 ? "Merchandised" : "Pending")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(vehicle.progress == 1.0 ? .black : .white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(vehicle.progress == 1.0 ? Color.green : Color.white.opacity(0.12))
                    .cornerRadius(4)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Add vehicle Modal sheet

struct AddVehicleSheet: View {
    @Binding var year: Int
    @Binding var make: String
    @Binding var model: String
    @Binding var trim: String
    @Binding var colorIndex: Int
    
    var colors: [(name: String, hex: String)]
    var onSave: () -> Void
    var onDismiss: () -> Void
    
    var isFormValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("VEHICLE DETAILS").foregroundColor(.white.opacity(0.6))) {
                    Picker("Year", selection: $year) {
                        ForEach(2020...2027, id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    TextField("Make (e.g. BMW, Tesla)", text: $make)
                        .foregroundColor(.white)
                        .listRowBackground(Color.white.opacity(0.05))
                    
                    TextField("Model (e.g. M4, Model X)", text: $model)
                        .foregroundColor(.white)
                        .listRowBackground(Color.white.opacity(0.05))
                    
                    TextField("Trim (e.g. Competition, Plaid)", text: $trim)
                        .foregroundColor(.white)
                        .listRowBackground(Color.white.opacity(0.05))
                }
                
                Section(header: Text("EXTERIOR COLOR").foregroundColor(.white.opacity(0.6))) {
                    Picker("Paint Color", selection: $colorIndex) {
                        ForEach(0..<colors.count, id: \.self) { idx in
                            HStack {
                                Circle()
                                    .fill(Color(hex: colors[idx].hex))
                                    .frame(width: 12, height: 12)
                                Text(colors[idx].name)
                            }
                            .tag(idx)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#09090b"))
            .navigationTitle("Add Vehicle to Lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(.cyan)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .foregroundColor(isFormValid ? .cyan : .white.opacity(0.2))
                        .disabled(!isFormValid)
                }
            }
        }
    }
}
