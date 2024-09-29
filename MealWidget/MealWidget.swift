import WidgetKit
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

struct MealEntry: TimelineEntry {
    let date: Date
    let meal: Meal?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MealEntry {
        MealEntry(date: Date(), meal: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MealEntry) -> ()) {
        let entry = MealEntry(date: Date(), meal: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MealEntry>) -> ()) {
        // Fetch meal data for today
        fetchMealData { meal in
            let entry = MealEntry(date: Date(), meal: meal)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func fetchMealData(completion: @escaping (Meal?) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let today = formatter.string(from: Date())

        let urlString = "https://school-api-1i8w.onrender.com/lunch?startdate=\(today)&enddate=\(today)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let meals = try decoder.decode([Meal].self, from: data)
                completion(meals.first) // Return the first meal for today
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

struct MealWidgetEntryView: View {
    var entry: MealEntry

    var body: some View {
        VStack {
            if let meal = entry.meal {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .font(.callout)
                        Text("Lunch Menu")
                            .font(.headline)
                    }
                    .padding(.leading, -2)
                    .padding(.top, -4)
                    Text(meal.DDISH_NM.replacingOccurrences(of: "\n", with: ", "))
                        .font(.body)
                        .bold()
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                }
                .padding(.leading, -10)
                
            } else {
                Text("No menu to display")
                    .font(.body)
                    .bold()
            }
        }
        .containerBackground(Color.gray.gradient, for: .widget) // This ensures the widget background adapts correctly
    }
}

@main
struct MealWidget: Widget {
    let kind: String = "MealWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MealWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Meal")
        .description("Displays today's meal information.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

