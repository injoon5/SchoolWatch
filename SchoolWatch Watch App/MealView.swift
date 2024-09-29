//
//  MealView.swift
//  SchoolWatch
//
//  Created by Injoon Oh on 9/28/24.
//

import SwiftUI

// Data models
struct Meal: Identifiable, Codable {
    let id = UUID()
    let MLSV_YMD: String // Meal date
    let DDISH_NM: String // Dishes
    let CAL_INFO: String // Calories
    let NTR_INFO: String // Nutritional Info
    let ORPLC_INFO: String // Origin Info
}

struct MealData: Codable {
    let meals: [Meal]
    let update_date: String
}

struct MealView: View {
    @State private var mealData: MealData?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        if let meals = mealData?.meals {
                            ForEach(meals) { meal in
                                VStack(alignment: .leading) {
                                    Text("\(formatDate(meal.MLSV_YMD))")
                                        .font(.caption)
                                        .padding(.top, 2)
                                        .foregroundColor(.gray)
                                    Text(meal.DDISH_NM.replacingOccurrences(of: "\n", with: ", "))
                                        .font(.headline)
                                    
                                    Text("\(meal.CAL_INFO)")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                    
                                    
                                }
                                .padding(.vertical, 4)
                            
                            }
                            if let updateDate = mealData?.update_date {
                                Text("Last updated: \(formatUpdateDate(updateDate))")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 10)
                            }
                        }
                    }
                    .navigationTitle("Meals")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .onAppear {
                loadMealData()
            }
        }
    }
    
    private func loadMealData() {
        // Start date and end date calculation
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        let startDate = formatter.string(from: Date())
        let endDate = formatter.string(from: Calendar.current.date(byAdding: .day, value: 15, to: Date())!)
        
        let grade = UserDefaults.standard.integer(forKey: "grade")
        let classno = UserDefaults.standard.integer(forKey: "classno")
        
        // Use defaults if values are not set
        let finalGrade = grade == 0 ? 2 : grade
        let finalClass = classno == 0 ? 6 : classno
        
        let urlString = "https://school-api-1i8w.onrender.com/lunch?grade=\(finalGrade)&classno=\(finalClass)&startdate=\(startDate)&enddate=\(endDate)"
            
            
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode([Meal].self, from: data)
                
                DispatchQueue.main.async {
                    self.mealData = MealData(meals: decodedData, update_date: Date().description)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d (EEE)" // Sep 30 (Mon)
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }

    
    private func formatUpdateDate(_ updateDate: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        if let date = dateFormatter.date(from: updateDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }
        return updateDate
    }
}

#Preview {
    MealView()
}
