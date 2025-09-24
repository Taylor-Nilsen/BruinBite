//
//  ContentView.swift
//  BruinBite
//
//  Created by Taylor Nilsen on 9/22/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var diningVM = DiningViewModel()
    
    var body: some View {
        TabView {
            // Study tab with combined functionality
            NavigationStack {
                LibraryListView()
            }
            .tabItem {
                Label("Study", systemImage: "books.vertical")
            }
            
            // Dining Hall tab
            NavigationStack {
                DiningListView(vm: diningVM, mode: .halls)
            }
            .tabItem {
                Label("Halls", systemImage: "fork.knife")
            }
            
            // Campus Dining tab
            NavigationStack {
                DiningListView(vm: diningVM, mode: .campus)
            }
            .tabItem {
                Label("Campus", systemImage: "building.2")
            }
            
            // Gym tab
            NavigationStack {
                GymView()
            }
            .tabItem {
                Label("Gym", systemImage: "figure.walk")
            }
        }
    }
}

#Preview {
    ContentView()
}
