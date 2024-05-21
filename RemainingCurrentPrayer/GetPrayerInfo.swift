import Foundation

struct PrayerTimes: Decodable {
    let province: String
    let city: String
    let date: String
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
}

func loadPrayerTimes(for date: Date, province: String, city: String) -> PrayerTimes? {
    guard let url = Bundle.main.url(forResource: "prayer_times", withExtension: "json") else {
        print("Error: File not found")
        return nil
    }
    do {
        let data = try Data(contentsOf: url)
        let prayerTimesArray = try JSONDecoder().decode([PrayerTimes].self, from: data)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        let targetDate = dateFormatter.string(from: date)

        return prayerTimesArray.first { $0.date == targetDate && $0.province == province && $0.city == city }
    } catch {
        print("Error loading JSON: \(error)")
        return nil
    }
}

func getCurrentPrayerName(currentTime: Date, prayerTimes: PrayerTimes) -> String {
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    
    func timeToComponents(_ time: String) -> DateComponents? {
        guard let date = dateFormatter.date(from: time) else { return nil }
        return calendar.dateComponents([.hour, .minute], from: date)
    }
    
    func createDate(components: DateComponents) -> Date? {
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: currentTime)
    }
    
    guard
        let fajrComponents = timeToComponents(prayerTimes.fajr),
        let sunriseComponents = timeToComponents(prayerTimes.sunrise),
        let dhuhrComponents = timeToComponents(prayerTimes.dhuhr),
        let asrComponents = timeToComponents(prayerTimes.asr),
        let maghribComponents = timeToComponents(prayerTimes.maghrib),
        let ishaComponents = timeToComponents(prayerTimes.isha)
    else {
        print("Error: Invalid prayer times format")
        return "Invalid prayer times"
    }
    
    guard
        let fajrTime = createDate(components: fajrComponents),
        let sunriseTime = createDate(components: sunriseComponents),
        let dhuhrTime = createDate(components: dhuhrComponents),
        let asrTime = createDate(components: asrComponents),
        let maghribTime = createDate(components: maghribComponents),
        let ishaTime = createDate(components: ishaComponents)
    else {
        print("Error: Unable to create dates from components")
        return "Invalid prayer times"
    }
    
    if currentTime >= fajrTime && currentTime < sunriseTime {
        return "Fajr"
    } else if currentTime >= sunriseTime && currentTime < dhuhrTime {
        return "Sunrise"
    } else if currentTime >= dhuhrTime && currentTime < asrTime {
        return "Dhuhr"
    } else if currentTime >= asrTime && currentTime < maghribTime {
        return "Asr"
    } else if currentTime >= maghribTime && currentTime < ishaTime {
        return "Maghrib"
    } else {
        return "Isha"
    }
}

func getNextPrayerTime(currentTime: Date, prayerTimes: PrayerTimes) -> Date? {
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"

    func timeToDate(_ time: String) -> Date? {
        guard let date = dateFormatter.date(from: time) else { return nil }
        return calendar.date(bySettingHour: calendar.component(.hour, from: date), minute: calendar.component(.minute, from: date), second: 0, of: currentTime)
    }

    guard
        let fajrDate = timeToDate(prayerTimes.fajr),
        let sunriseDate = timeToDate(prayerTimes.sunrise),
        let dhuhrDate = timeToDate(prayerTimes.dhuhr),
        let asrDate = timeToDate(prayerTimes.asr),
        let maghribDate = timeToDate(prayerTimes.maghrib),
        let ishaDate = timeToDate(prayerTimes.isha)
    else {
        print("Error: Unable to create dates from prayer times")
        return nil
    }

    let prayerTimesArray: [Date] = [fajrDate, sunriseDate, dhuhrDate, asrDate, maghribDate, ishaDate].compactMap { $0 }

    let filteredPrayerTimes = prayerTimesArray.filter { $0 > currentTime }

    return filteredPrayerTimes.first
}

