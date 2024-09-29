//
//  Utilities.swift
//  SchoolWatch
//
//  Created by Injoon Oh on 9/28/24.
//

import Foundation

public func getWeekdayNamesOfCurrentWeek() -> [String] {
    let calendar = Calendar.current
    let today = Date()
    
    // Get the current week range (Sunday to Saturday)
    guard let weekRange = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
    
    var weekdayNames: [String] = []
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d (EEE)" // Full weekday name (e.g., "Monday")
    
    // Iterate over all days of the week
    for weekday in 1...7 { // 1 = Sunday, 7 = Saturday
        if let weekdayDate = calendar.date(byAdding: .day, value: weekday - 1, to: weekRange.start) {
            let weekdayName = dateFormatter.string(from: weekdayDate)
            weekdayNames.append(weekdayName)
        }
    }
    
    return weekdayNames
}

public func formattedDateForTitle() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d (E)"
    let formattedDate = dateFormatter.string(from: Date())
    
    return formattedDate
}

public func getTimeFromPeriod(periodString: String) -> String {
    let components = periodString.split(separator: "(")
    
    // Ensure there are two components, and the second component has a closing parenthesis
    guard components.count == 2, components[1].hasSuffix(")") else {
        return "Invalid format"
    }
    
    // Extract the time string and remove the closing parenthesis
    let timeString = components[1].replacingOccurrences(of: ")", with: "")
    
    // Create a DateFormatter to parse the time
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    
    // Get the current date
    let now = Date()
    
    // Parse the provided time string to create a date object
    guard let timeDate = formatter.date(from: timeString) else {
        return "Invalid time format"
    }
    
    // Get the calendar to adjust the time
    let calendar = Calendar.current
    
    // Combine the current date with the provided time's hour and minute
    let currentTimeComponents = calendar.dateComponents([.year, .month, .day], from: now)
    let combinedDate = calendar.date(bySettingHour: calendar.component(.hour, from: timeDate),
                                      minute: calendar.component(.minute, from: timeDate),
                                      second: 0,
                                      of: calendar.date(from: currentTimeComponents)!)!

    // Format the now time and the future time
    let nowTimeString = formatter.string(from: combinedDate)
    let futureTime = calendar.date(byAdding: .minute, value: 45, to: combinedDate)!
    let futureTimeString = formatter.string(from: futureTime)

    return "\(nowTimeString)~\(futureTimeString)"
}
