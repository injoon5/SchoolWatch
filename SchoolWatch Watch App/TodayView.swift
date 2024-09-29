import SwiftUI

struct TodayView: View {
    @State private var todaySchedule: DaySchedule?
    @State private var todayMeal: Meal?
    @State private var errorMessage: String?
    @State private var isWeekend: Bool = false
    @State private var timetableData: TimetableData?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage, onRetry: loadTodayData)
                } else if isWeekend {
                    Text("NO SCHOOL TODAY!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.red)
                        .padding()
                    
                } else {
                    
                    List {
                        if let todaySchedule = todaySchedule {
                            Section(header: Text("Classes").font(.title3).bold()) {
                                ForEach(todaySchedule.classes) { classSchedule in
                                    ClassScheduleRow(classSchedule: classSchedule, timetableData: timetableData)
                                }
                            }
                        }
                        
                        if let todayMeal = todayMeal {
                            Section(header: Text("Menu").font(.title3).bold()) {
                                VStack(alignment: .leading) {
                                    Text(todayMeal.DDISH_NM.replacingOccurrences(of: "\n", with: ", "))
                                        .font(.headline)
                                    Text("\(todayMeal.CAL_INFO)")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .navigationTitle("\(formattedDateForTitle())")
                }
            }
            .onAppear {
                loadTodayData()
            }
        }
    }
    
    private func loadTodayData() {
        let calendar = Calendar.current
        let today = Date()
        let midnight = calendar.startOfDay(for: today)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: midnight)!
        let weekday = calendar.component(.weekday, from: tomorrow)
        
        if weekday == 1 || weekday == 7 {
            // Weekend: Sunday (1) or Saturday (7)
            isWeekend = true
            return
        } else {
            // Weekday: Load data
            isWeekend = false
            loadTodaySchedule()
            loadTodayMeal()
        }
    }
    
    private func loadTodaySchedule() {
        let grade = UserDefaults.standard.integer(forKey: "grade")
        let classno = UserDefaults.standard.integer(forKey: "classno")
        
        // Use defaults if values are not set
        let finalGrade = grade == 0 ? 2 : grade
        let finalClass = classno == 0 ? 6 : classno
        
        let urlString = "https://school-api-1i8w.onrender.com/timetable?grade=\(finalGrade)&classno=\(finalClass)"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch timetable: \(error.localizedDescription)"
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
                let decodedData = try decoder.decode(TimetableData.self, from: data)
                let calendar = Calendar.current
                let weekdayIndex = calendar.component(.weekday, from: Date()) - 2 // Monday is 0
                //print(weekdayIndex)
                DispatchQueue.main.async {
                    self.timetableData = decodedData
                    if weekdayIndex >= 0 && weekdayIndex < decodedData.timetable.count {
                        self.todaySchedule = DaySchedule(classes: decodedData.timetable[weekdayIndex])
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode timetable: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func loadTodayMeal() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let todayDate = formatter.string(from: Date())
        print(todayDate)
        let urlString = "https://school-api-1i8w.onrender.com/lunch?startdate=\(todayDate)&enddate=\(todayDate)"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    
                    self.errorMessage = "Failed to fetch meal data: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No meal data received"
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode([Meal].self, from: data)
                
                DispatchQueue.main.async {
                    if let firstMeal = decodedData.first {
                        self.todayMeal = firstMeal
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isWeekend = true
                    //self.errorMessage = "Failed to decode meal data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
    }
}
