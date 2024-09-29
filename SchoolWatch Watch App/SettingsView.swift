//
//  SettingsView.swift
//  SchoolWatch
//
//  Created by Injoon Oh on 9/29/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("grade") private var selectedGrade: Int = UserDefaults.standard.integer(forKey: "grade") == 0 ? 2 : UserDefaults.standard.integer(forKey: "grade")
    @AppStorage("classno") private var selectedClass: Int = UserDefaults.standard.integer(forKey: "classno") == 0 ? 6 : UserDefaults.standard.integer(forKey: "classno")
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Grade")) {
                    Picker("Select Grade", selection: $selectedGrade) {
                        ForEach(1...3, id: \.self) { grade in
                            Text("Grade \(grade)").tag(grade)
                        }
                    }
                }
                
                Section(header: Text("Class")) {
                    Picker("Select Class", selection: $selectedClass) {
                        ForEach(1...15, id: \.self) { classno in
                            Text("Class \(classno)").tag(classno)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        

    }
}


#Preview {
    SettingsView()
}
