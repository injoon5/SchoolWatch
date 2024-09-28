import SwiftUI

// Data models
struct ClassSchedule: Identifiable, Codable {
    let id = UUID()
    let period: Int
    let subject: String
    let teacher: String
    let replaced: Bool
    let original: OriginalClass?
}

struct OriginalClass: Codable {
    let period: Int
    let subject: String
    let teacher: String
}

struct DaySchedule: Identifiable {
    let id = UUID()
    var classes: [ClassSchedule]
}

struct TimetableData: Codable {
    let day_time: [String]
    let timetable: [[ClassSchedule]]
    let update_date: String
}

let weekDayNames = getWeekdayNamesOfCurrentWeek()
var todayWeekdayIndex: Int? {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())
    return (weekday >= 2 && weekday <= 6) ? weekday - 2 : nil // 0 for Monday, 1 for Tuesday, ..., 4 for Friday
}

struct TimetableView: View {
    @State private var timetableData: TimetableData?
    @State private var daySchedules: [DaySchedule] = []
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                VStack {
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        List {
                            ForEach(Array(daySchedules.enumerated()), id: \.element.id) { index, daySchedule in
                                Section(header: Text("\(weekDayNames[index + 1])").id(index)) {
                                    ForEach(daySchedule.classes) { classSchedule in
                                        NavigationLink(destination: ClassDetailView(classSchedule: classSchedule, timetableData: timetableData)) {
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text(classSchedule.subject)
                                                        .font(.headline)
                                                    if classSchedule.replaced {
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .foregroundColor(.yellow)
                                                    }
                                                }
                                                
                                                Text("\(getTimeFromPeriod(periodString: timetableData?.day_time[classSchedule.period - 1] ?? ""))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                                
                                                Text("\(classSchedule.teacher)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .id(index)
                            }
                            if let updateDate = timetableData?.update_date {
                                Text("Last updated: \(formatUpdateDate(updateDate))")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 10)
                            }
                        }
                        .navigationTitle("Timetable")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .toolbar {
                    //if todayWeekdayIndex >= 0 && todayWeekdayIndex <= 4 {
                    if true {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation {
                                    scrollProxy.scrollTo(3, anchor: .top)
                                }
                            } label: {
                                Image(systemName:"clock")
                            }
                        }
                    }
                                                
                }
            }
            .onAppear {
                loadTimetableData()
            }
            
        }
    }
    
    private func loadTimetableData() {
        // API URL
        let urlString = "https://school-api-1i8w.onrender.com/timetable?grade=2&classno=6"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            loadCachedData() // Attempt to load cached data if the URL is invalid
            return
        }
        
        let request = URLRequest(url: url)
        
        // Network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    loadCachedData() // Load cached data on failure
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                    loadCachedData() // Load cached data if no data is received
                }
                return
            }
            
            do {
                // Decode the response
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(TimetableData.self, from: data)
                
                // Cache the data
                saveTimetableToCache(timetableData: decodedData)
                
                DispatchQueue.main.async {
                    self.timetableData = decodedData
                    self.daySchedules = decodedData.timetable.map { DaySchedule(classes: $0) }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                    loadCachedData() // Load cached data if decoding fails
                }
            }
        }.resume()
    }
    
    private func loadCachedData() {
        if let cachedData = getCachedTimetable() {
            self.timetableData = cachedData
            self.daySchedules = cachedData.timetable.map { DaySchedule(classes: $0) }
        } else {
            self.errorMessage = "No cached data available."
        }
    }
    
    private func saveTimetableToCache(timetableData: TimetableData) {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(timetableData) {
            UserDefaults.standard.set(encodedData, forKey: "cachedTimetable")
        }
    }
    
    private func getCachedTimetable() -> TimetableData? {
        if let cachedData = UserDefaults.standard.data(forKey: "cachedTimetable") {
            let decoder = JSONDecoder()
            if let decodedTimetable = try? decoder.decode(TimetableData.self, from: cachedData) {
                return decodedTimetable
            }
        }
        return nil
    }
    
    // Extracts just the time from the period string (e.g., "1(08:50)" becomes "08:50")
    private func getTimeFromPeriod(periodString: String) -> String {
        let components = periodString.split(separator: "(")
        if components.count == 2 {
            return components[1].replacingOccurrences(of: ")", with: "")
        }
        return periodString
    }
    
    // Formats the update date (assuming the format is "yyyy-MM-dd HH:mm:ss")
    private func formatUpdateDate(_ updateDate: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: updateDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .short
            return outputFormatter.string(from: date)
        }
        return updateDate
    }
}

// Detail view for each class
struct ClassDetailView: View {
    let classSchedule: ClassSchedule
    let timetableData: TimetableData?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {

                Text("\(classSchedule.subject)")
                        .font(.title)
                        .bold()


                Text("\(classSchedule.teacher)")
                        .font(.title2)
                        .padding(.bottom, 10)
                

                Text("\(getTimeFromPeriod(periodString: timetableData?.day_time[classSchedule.period - 1] ?? ""))")
                        .font(.title3)
                        .padding(.bottom, 10)

                if classSchedule.replaced, let original = classSchedule.original {
                    Text("Replaced \(original.subject) (\(original.teacher))")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .navigationTitle("Class Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TimetableView()
}
