//
//  ContentView.swift
//  SchoolWatch Watch App
//
//  Created by Injoon Oh on 9/28/24.
//

import SwiftUI



struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
            TimetableView()
            MealView()
            SettingsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
}
