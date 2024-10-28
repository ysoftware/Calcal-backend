import Foundation

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMMM yyyy"
    return formatter
}()

extension String {
    var floatValue: Float? {
        guard !self.isEmpty else { return nil }
        return Float(self.replacingOccurrences(of: ",", with: "."))
    }
}

struct Mapper {
    
    static func measurementDisplayValue(
        quantity: Float,
        measurement: EntryEntity.QuantityMeasurement
    ) -> String {
        let baseQuantity = quantity
            .formatted
            .replacingOccurrences(of: ",", with: ".")
        
        let multipliedQuantity = (quantity*1000)
            .formatted
            .replacingOccurrences(of: ",", with: ".")
        
        switch measurement {
        case .portion:
            if quantity == 1 {
                return "1"
            }
            return "\(baseQuantity)"
        case .cup:
            if quantity == 1 {
                return "1 cup"
            }
            return "\(baseQuantity) cups"
        case .liter:
            if quantity > 0.5 {
                return "\(baseQuantity) l"
            }
            return "\(multipliedQuantity) ml"
        case .kilogram:
            if quantity > 0.5 {
                return "\(baseQuantity) kg"
            }
            return "\(multipliedQuantity) g"
        }
    }
    
    
    static func map(entity: EntryEntity) -> String {
        var entryText = ""
        var totalCalories: Float = 0
        
        for section in entity.sections {
            var itemsText = ""
            var sectionCalories: Float = 0
            
            for item in section.items {
                let quantityValue = Self.measurementDisplayValue(
                    quantity: item.quantity,
                    measurement: item.measurement
                )
                itemsText.append("- \(item.title), \(quantityValue), \(item.calories.formatted) kcal\n")
                sectionCalories += item.calories
            }
            
            entryText.append("\(section.id) - \(sectionCalories.formatted) kcal\n\(itemsText)\n")
            totalCalories += sectionCalories
        }
        
        return """
        Date: \(entity.date)
        
        \(entryText.trimmingCharacters(in: .whitespacesAndNewlines))
        
        Total: \(totalCalories.calorieValue)
        """
    }
    
    static func month(number: Int) -> String {
        switch number {
        case 1: return "January"
        case 2: return "February"
        case 3: return "March"
        case 4: return "April"
        case 5: return "May"
        case 6: return "June"
        case 7: return "July"
        case 8: return "August"
        case 9: return "September"
        case 10: return "October"
        case 11: return "November"
        case 12: return "December"
        default: return ""
        }
    }
}

extension Array where Element == Int {
    var average: Int {
        guard !isEmpty else { return 0 }
        return sorted().reduce(0, +) / count
    }
}

extension Float {
    var calorieValue: String {
        "\(self.formatted) kcal"
    }
    
    var formatted: String {
        self.formatted(.number.rounded().grouping(.never))
    }
}

struct CaloricInformation {
    let value: Float
    let measurement: EntryEntity.QuantityMeasurement
}

struct PopularItem {
    let title: String
    let occurencesCount: Int
    let quantity: Float
    let measurement: EntryEntity.QuantityMeasurement
    let calories: Float
}
