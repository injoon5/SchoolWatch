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

struct Event: Identifiable, Codable {
    let id = UUID()
    let AA_YMD: String // Date of the event
    let EVENT_NM: String // Event name
    let SBTR_DD_SC_NM: String
    let ONE_GRADE_EVENT_YN: String
    let TW_GRADE_EVENT_YN: String
    let THREE_GRADE_EVENT_YN: String
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
    @State private var events: [Event] = []
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    var body: some View {
        if isLoading {
            ProgressView()
        }
        else {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    VStack {
                        if let errorMessage = errorMessage {
                            ErrorView(message: errorMessage, onRetry: loadTimetableData)
                        } else {
                            TimetableListView(daySchedules: daySchedules, timetableData: timetableData, events: events)
                        }
                    }
                    .navigationTitle("Timetable")
                    .navigationBarTitleDisplayMode(.inline)
                    //.toolbar {
                     //   ToolbarItem(placement: .topBarLeading) {
                         //   TodayButton(scrollProxy: scrollProxy)
                      //  }
                   // }
                }
                .onAppear {
                    loadTimetableData()
                }
            }
        }
    }
    
    private func loadTimetableData() {
        let grade = UserDefaults.standard.integer(forKey: "grade")
        let classno = UserDefaults.standard.integer(forKey: "classno")
        
        // Use defaults if values are not set
        let finalGrade = grade == 0 ? 2 : grade
        let finalClass = classno == 0 ? 6 : classno
        
        let urlString = "https://school-api-1i8w.onrender.com/timetable?grade=\(finalGrade)&classno=\(finalClass)"
               
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            loadCachedData()
            return
        }
        if (UserDefaults.standard.data(forKey: "cachedTimetable") == nil) {
            isLoading = true
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    loadCachedData()
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                    loadCachedData()
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(TimetableData.self, from: data)
                
                saveTimetableToCache(timetableData: decodedData)
                
                DispatchQueue.main.async {
                    self.timetableData = decodedData
                    self.daySchedules = decodedData.timetable.map { DaySchedule(classes: $0) }
                }
                fetchEvents() // Fetch events after loading timetable data
                isLoading = false
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                    
                    loadCachedData()
                }
            }
        }.resume()
    }
    
    private func fetchEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let today = Date()

        var calendar = Calendar.current
        calendar.firstWeekday = 1  // Sunday
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        let startDateString = dateFormatter.string(from: startOfWeek)
        let endDateString = dateFormatter.string(from: endOfWeek)
        
        let eventURLString = "https://school-api-1i8w.onrender.com/schedule?startdate=\(startDateString)&enddate=\(endDateString)&schoolname=%EB%AA%A9%EC%9A%B4%EC%A4%91%ED%95%99%EA%B5%90"
        
        guard let url = URL(string: eventURLString) else {
            self.errorMessage = "Invalid event URL"
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch events: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No event data received"
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedEvents = try decoder.decode([Event].self, from: data)
                
                DispatchQueue.main.async {
                    print(request)
                    self.events = decodedEvents
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode event data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    
    private func loadCachedData() {
        if let cachedData = getCachedTimetable() {
            self.timetableData = cachedData
            self.daySchedules = cachedData.timetable.map { DaySchedule(classes: $0) }
            isLoading = false
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
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack {
            Text("Error: \(message)")
                .foregroundColor(.red)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onRetry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .padding()
            }
        }
    }
}

struct TimetableListView: View {
    let daySchedules: [DaySchedule]
    let timetableData: TimetableData?
    let events: [Event]
    
    var body: some View {
        List {
            ForEach(Array(daySchedules.enumerated()), id: \.element.id) { index, daySchedule in
                let matchingEvent = events.first { $0.AA_YMD == getDateString(for: index + 1) && $0.TW_GRADE_EVENT_YN == "Y" }
                
                Section(header: Text("\(weekDayNames[index + 1])").id(index)) {
                    if let event = matchingEvent {
                        NavigationLink(destination: EventDetailView(event: event)) {
                            Text(event.EVENT_NM)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                        }
                    } else {
                        ForEach(daySchedule.classes) { classSchedule in
                            ClassScheduleRow(classSchedule: classSchedule, timetableData: timetableData)
                        }
                    }
                }
            }
            if let updateDate = timetableData?.update_date {
                Text("Last updated: \(formatUpdateDate(updateDate))")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
        }
    }
    
    private func getDateString(for weekdayIndex: Int) -> String {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        let targetDate = calendar.date(byAdding: .day, value: weekdayIndex, to: startOfWeek)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: targetDate)
    }
    
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

struct EventDetailView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .center) {
            Text(event.EVENT_NM)
                .font(.title)
                .bold()
            
            
            Text("\(formatEventDate(event.AA_YMD))")
                .font(.headline)
                .foregroundColor(.gray)
            Text("\(formatEventDate(event.SBTR_DD_SC_NM))")
                .font(.title3)
                .foregroundColor(.gray)
            
            HStack {
                if event.ONE_GRADE_EVENT_YN == "Y" {
                    
                    Label("Grade 1", systemImage: "1.circle")
                        .font(.title2)
                        .labelStyle(.iconOnly)
                }
                if event.TW_GRADE_EVENT_YN == "Y" {
                    Label("Grade 2", systemImage: "2.circle")
                        .font(.title2)
                        .labelStyle(.iconOnly)
                }
                if event.THREE_GRADE_EVENT_YN == "Y" {
                    Label("Grade 3", systemImage: "3.circle")
                        .font(.title2)
                        .labelStyle(.iconOnly)
                }
            }
            .padding(.top)
        }
        .padding()
        .navigationTitle("Event Details")
    }
    
    private func formatEventDate(_ eventDate: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        if let date = dateFormatter.date(from: eventDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }
        return eventDate
    }
}

struct ClassScheduleRow: View {
    let classSchedule: ClassSchedule
    let timetableData: TimetableData?
    
    var body: some View {
        NavigationLink(destination: ClassDetailView(classSchedule: classSchedule, timetableData: timetableData)) {
            HStack(alignment: .top) {
                Text("\(classSchedule.period)")
                    .padding(.trailing)
                    .font(.title3)
                    .bold()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(classSchedule.subject)
                            .font(.headline)
                        if classSchedule.replaced {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.yellow)
                        }
                    }
                    Text("\(classSchedule.teacher)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(getTimeFromPeriod(periodString: timetableData?.day_time[classSchedule.period - 1] ?? ""))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func getTimeFromPeriod(periodString: String) -> String {
        let components = periodString.split(separator: "(")
        if components.count == 2 {
            return components[1].replacingOccurrences(of: ")", with: "")
        }
        return periodString
    }
}

struct ClassDetailView: View {
    let classSchedule: ClassSchedule
    let timetableData: TimetableData?
    
    var body: some View {
        VStack(alignment: .center) {

            Text("\(classSchedule.subject)")
                    .font(.title)
                    .bold()


            Text("\(classSchedule.teacher)")
                    .font(.title2)
                    .padding(.bottom, 10)
            

            Text("\(getTimeFromPeriod(periodString: timetableData?.day_time[classSchedule.period - 1] ?? ""))")
                    .font(.title3)
                    .foregroundColor(.gray)
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


struct TodayButton: View {
    let scrollProxy: ScrollViewProxy
    
    var body: some View {
        if let todayWeekdayIndex = todayWeekdayIndex, todayWeekdayIndex <= 4 {
            Button {
                withAnimation {
                    scrollProxy.scrollTo(todayWeekdayIndex, anchor: .top)
                }
            } label: {
                Image(systemName: "clock")
            }
        } else {
            Button {} label: {
                Image(systemName: "clock")
            }
            .disabled(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimetableView()
                
            EventDetailView(event: Event(AA_YMD: "20241001", EVENT_NM: "한글날", SBTR_DD_SC_NM: "공휴일", ONE_GRADE_EVENT_YN: "Y", TW_GRADE_EVENT_YN: "Y", THREE_GRADE_EVENT_YN: "Y"))
                
        }
    }
}

