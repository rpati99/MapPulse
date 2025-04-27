//
//  MapView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/19/25.
//


import SwiftUI
import Combine

struct MapView: View {
    @StateObject private var vm = NetworkTestViewModel(interval: 15)
    @State private var selectedDeviceID: String?
    @State private var isSearchExpanded = false
    @State private var showPhotoPicker = false
    @FocusState private var searchFieldFocused: Bool
    @State private var searchText = ""
    @State private var debouncedSearch = ""
    @Namespace private var Namespace
    @AppStorage("sortOption") private var sortOption : SortOption = .none
    private let debouncePublisher = PassthroughSubject<String, Never>()
    @State private var lastScrolledID: String?
    @StateObject private var hiddenDeviceService = HiddenDeviceService()
    @AppStorage("showHiddenDevices") private var showHidden = false
    
    // Build your sorted + filtered list:
    private var displayDevices: [Device] {
        // a) first, sort according to your enum
        let sorted: [Device]
        switch sortOption {
        case .altitude:
            sorted = vm.devices.sorted { a, b in
                (a.latestPoint?.altitude ?? 0) > (b.latestPoint?.altitude ?? 0)
            }
        case .speed:
            sorted = vm.devices.sorted { a, b in
                (a.latestPoint?.speed  ?? 0) > (b.latestPoint?.speed  ?? 0)
            }
        case .driveStatus:
            sorted = vm.devices.sorted { a, b in
                let aStatus = a.latestPoint?.deviceState?.driveStatus ?? ""
                let bStatus = b.latestPoint?.deviceState?.driveStatus ?? ""
                return aStatus.localizedCompare(bStatus) == .orderedAscending
            }
        case .none:
            sorted = vm.devices
        }
        
        let unhidden = sorted.filter { showHidden || !hiddenDeviceService.isHidden($0.id) }
        // b) then apply your search‐text filter
        guard !searchText.isEmpty else {
            return unhidden
        }
        return unhidden.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            contentView
            
            // ─────── The Carousel + Search UI ───────
            VStack(spacing: 8) {
                // ───────────────────────
                //  Glass-morphic Sort Button
                // ───────────────────────
                // MARK: Animated Expandable Search Bar
                // ───────── Glass-morphic Search Bar ─────────
                // inside your VStack (just replace the old search-bar block)
                if case .success = vm.state {
                    HStack(spacing: 10) {
                        // 1) Our “pill” itself
                        HStack(spacing: 8) {
                            Image(systemName: "car")
                                .foregroundColor(.white.opacity(0.9))
                            if isSearchExpanded {
                                TextField("Search drivers…", text: $searchText)
                                    .autocorrectionDisabled()
                                    .autocapitalization(.none)
                                    .focused($searchFieldFocused)
                                    .textFieldStyle(.plain)
                                    .submitLabel(.search)
                                    .onSubmit { searchFieldFocused = false }
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.thinMaterial, in:
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(radius: 4)
                        // Collapse to just the icon when not expanded
                        .frame(width: isSearchExpanded ? nil : 44,alignment: .leading)
                        
                        
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isSearchExpanded = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(nil) {
                                    searchFieldFocused = true
                                }
                            }
                        }
                        
                        // 2) Push everything left, keep "Cancel" on right
                        Spacer()
                        
                        if isSearchExpanded {
                            Button("Cancel") {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    searchText = ""
                                    isSearchExpanded = false
                                    searchFieldFocused = false
                                }
                            }
                            
                            .padding(.leading, 8)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    HStack {
                        Menu {
                            Picker("Sort by", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { opt in
                                    Text(opt.rawValue.capitalized)
                                        .tag(opt)
                                }
                            }
                            Divider()
                            Toggle("Show Hidden", isOn: $showHidden)   // << new
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .font(.title2)
                                .padding(8)
                                .tint(.white)
                                .background(.ultraThinMaterial, in:
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .shadow(radius: 4)
                        .padding(.horizontal)
                        Spacer()
                    }
                    
                    Spacer()
                    // 2) Carousel in a ScrollViewReader
                    
                    ScrollViewReader { proxy in
                        DeviceCarouselView(devices: displayDevices, namespace: Namespace, onCardTap: { device in
                            withAnimation {
                                selectedDeviceID = (selectedDeviceID == device.id ? nil : device.id)
                            }
                        }, selectedDeviceID: $selectedDeviceID)
                        .environmentObject(hiddenDeviceService)
                        
                        .onReceive(
                            debouncePublisher
                                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                                .removeDuplicates()

                        ) { _ in
                          
                            guard let firstID = displayDevices.first?.id, firstID != lastScrolledID else {
                                   return
                                 }
                                withAnimation {
                                  proxy.scrollTo(firstID, anchor: .center)
                                }
                        }.onChange(of: searchText) { debouncePublisher.send(searchText) }
                    }
                    .frame(height: selectedDeviceID == nil ? 260 : 400)
                    .padding(.bottom, 20)
                    .ignoresSafeArea(.keyboard,edges: .bottom)
                }
            }
           
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker{ image in
                if let id = selectedDeviceID, let img = image {
                    UserIconManager.saveUserIcon(img, for: id)
                }
                showPhotoPicker = false
                selectedDeviceID = nil
            }
        }
        .environmentObject(vm)
        .task {
            _ = await vm.fetchOnceAndPrint()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView("Loading devices…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .failure(let error):
            VStack(spacing: 16) {
                Text("Error: \(error.localizedDescription)")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    vm.restartPolling()
                }
                .buttonStyle(.borderedProminent)
            }.padding(.horizontal)
            
        case .success(let devices):
            ZStack(alignment: .bottom) {
                ClusteredMapView(
                    devices: devices,
                    onDeviceTap: { id in
                        // tapping an annotation also expands that card
                        withAnimation { selectedDeviceID = (selectedDeviceID == id ? nil : id) }
                        showPhotoPicker = true
                    }, selectedDeviceID: $selectedDeviceID
                )
                .ignoresSafeArea()
            }
        }
    }
}


extension NetworkTestViewModel {
    /// Expose a way to restart the polling from your VM
    func restartPolling() {
        pollingService.start()
    }
    func fetchOnceAndPrintTask() {
        Task { await fetchOnceAndPrint() }
    }
}

#Preview {
    MapView()
}

extension MapView {
    private enum SortOption: String, CaseIterable    {
        case none, altitude, driveStatus, speed
    }
}
