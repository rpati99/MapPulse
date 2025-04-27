//
//  MapView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/19/25.
//


import SwiftUI
import Combine

/*
 The main home screen that ties together polling device data, displays it on a map and in an animated carousel, and layers in search, sort, and hide/unhide controls—all in SwiftUI.
*/
struct MapView: View {
    // Parent SwiftUI states
    @StateObject private var vm = NetworkViewModel(interval: 8) // View Model
    @State private var selectedDeviceID: String? // Holds id of selected device
    @State private var isSearchExpanded = false // Indicator for search bar expanding animation service
    @State private var showPhotoPicker = false // Indicator for photo drawer to appear
    @FocusState private var searchFieldFocused: Bool // Focus indicator for keyboard appearance when searchbar appears
    @State private var lastScrolledID: String? // Holds last scrolled id
    @State private var searchText = "" // Holds query for performing search
    @Namespace private var Namespace  // for coordinating animation in sub views (card expansion, see DeviceListView.swift->DeviceDetailView.swift)
    @AppStorage("sortOption") private var sortOption : SortOption = .none // Storing and holding the sort option as state
    private let debouncePublisher = PassthroughSubject<String, Never>() // Reactive publisher for search debouncing

    @StateObject private var hiddenDeviceService = HiddenDeviceService() // Hiding device service
    @AppStorage("showHiddenDevices") private var showHidden = false // Storage and holding hidden devices
    
    // List calculation for showing exact devices as per preferences set/unset
    private var displayDevices: [Device] {
        // Sort option filter
        let sorted: [Device]
        switch sortOption {
        case .altitude:
            sorted = vm.devices.sorted { ($0.latestPoint?.altitude ?? 0) > ($1.latestPoint?.altitude ?? 0) }
        case .speed:
            sorted = vm.devices.sorted { ($0.latestPoint?.speed  ?? 0) > ($1.latestPoint?.speed  ?? 0) }
        case .driveStatus:
            sorted = vm.devices.sorted {
                let aStatus = $0.latestPoint?.deviceState?.driveStatus ?? ""
                let bStatus = $1.latestPoint?.deviceState?.driveStatus ?? ""
                return aStatus.localizedCompare(bStatus) == .orderedAscending
            }
        case .none:
            sorted = vm.devices
        }
        
        // Hide option filter
        let unhidden = sorted.filter { showHidden || !hiddenDeviceService.isHidden($0.id) }
        // Finally apply search‐text filter
        guard !searchText.isEmpty else {
            return unhidden
        }
        return unhidden.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // UI rendering
    var body: some View {
        ZStack(alignment: .leading) {
            // state driven rendering of View on home screen (Map view)
            contentView
            
            // Search bar, Sort Menu, Device List View, Device Detail View
            VStack(spacing: 8) {
                if case .success = vm.state {
                
                    SearchBarView(searchText: $searchText, isSearchExpanded: $isSearchExpanded) {
                        debouncePublisher.send(searchText)
                    }
                    
                    SortMenuView(sortOption: $sortOption, showHidden: $showHidden)
                    
                    Spacer()
                    // Carousel in a ScrollViewReader
                    ScrollViewReader { proxy in
                        // Device List View
                        DeviceListView(devices: displayDevices, namespace: Namespace, onCardTap: { device in
                            withAnimation {
                                selectedDeviceID = (selectedDeviceID == device.id ? nil : device.id)
                            }
                        }, selectedDeviceID: $selectedDeviceID)
                        .environmentObject(hiddenDeviceService) // pass the hidden device service
                        
                        // Search debouncing for 300 ms
                        .onReceive(
                            debouncePublisher
                                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                                .removeDuplicates()

                        ) { _ in
                          // If search then animate Device List View to show the searched device in list
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
                   
                }
            }
           
            .padding(.bottom, 8)
        }
//        .ignoresSafeArea(.keyboard, edges: .bottom)
        // Show image picker when tapped on annotation
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker{ image in
                // If saved image then show that image
                if let id = selectedDeviceID, let img = image {
                    UserIconManager.saveUserIcon(img, for: id)
                }
                showPhotoPicker = false
                selectedDeviceID = nil
            }
        }
        .environmentObject(vm) // Pass view model into this map view
        .task {
            _ = await vm.fetchOnceAndPrint() // one shot fetch for first time load
        }
    }
    
    // State driven Home screen rendering based on API response
    @ViewBuilder
    private var contentView: some View {
        switch vm.state {
            // Show progress rotating circle for loading
        case .idle, .loading:
            ProgressView("Loading devices…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Show screen with error and retry button
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
        // Show Clustered Map view (see ClusteredMapView.swift) when success
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


#Preview {
    MapView()
}

