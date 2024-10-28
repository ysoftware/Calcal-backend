import Foundation

class Parser {
    
    enum Error: Swift.Error {
        case expectedEntry
        case expectedEOF
        case expectedFoodItem
        case expectedCalorieValue
        case invalidQuantity
        case invalidCaloriesMissingKcal
        case invalidCalories
    }

    private let initialText: String
    private let endIndex: String.Index
    
    private var i: String.Index
    
    init(text: String) {
        self.initialText = text
        self.endIndex = text.endIndex
        self.i = text.startIndex
    }
    
    var textRemainder: Substring {
        initialText[i..<endIndex]
    }
    
    private func eatWhitespacesAndNewlines() {
        while (endIndex > i && textRemainder[i].isWhitespace) {
            advanceIfPossible(after: i)
        }
    }
    
    private func eatWhitespaces() {
        while (endIndex > i && textRemainder[i].isWhitespace && !textRemainder[i].isNewline) {
            advanceIfPossible(after: i)
        }
    }
    
    private func advanceIfPossible(after: String.Index) {
        if endIndex > after {
            i = textRemainder.index(after: after)
        } else {
            i = endIndex
        }
    }
    
    private func printErrorPosition() {
        let previousSymbols = self.textRemainder[self.i..<self.endIndex].prefix(100)
        print("Parser: Error occured right before this text:\n\(previousSymbols)")
    }
    
    func parse() throws -> [EntryEntity] {
        var entries: [EntryEntity] = []
        
        while (endIndex > i) {
            eatWhitespacesAndNewlines()
            guard textRemainder[i..<endIndex].starts(with: "Date: "),
                  let indexAfterDate = textRemainder.firstIndex(of: " ")
            else {
                printErrorPosition()
                throw Error.expectedEntry
            }
            advanceIfPossible(after: indexAfterDate)
            
            eatWhitespaces()
            guard let dateNewLineIndex = textRemainder.firstIndex(of: "\n")
            else {
                printErrorPosition()
                throw Error.expectedEOF
            }
            let dateString = String(textRemainder[i..<dateNewLineIndex]).trimmingCharacters(in: .whitespaces)
            advanceIfPossible(after: dateNewLineIndex)
            
            var sections: [EntryEntity.Section] = []
            
            while (endIndex > i) {
                eatWhitespaces()
                
                // Date means new entry
                if textRemainder[i..<endIndex].starts(with: "Date: ") {
                    break
                }
                
                guard let sectionSeparatorIndex = textRemainder.firstIndex(of: "-") else {
                    guard !sections.isEmpty else {
                        eatWhitespaces()
                        advanceIfPossible(after: i)
                        continue
                    }
                    break
                }
                
                let sectionName = String(textRemainder[i..<sectionSeparatorIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                advanceIfPossible(after: sectionSeparatorIndex)
                
                guard let sectionNewLineIndex = textRemainder.firstIndex(of: "\n") else {
                    printErrorPosition()
                    throw Error.expectedEOF
                }
                advanceIfPossible(after: sectionNewLineIndex)
                
                var foodItems: [EntryEntity.Item] = []
                
                while (endIndex > i) {
                    eatWhitespaces()
                    
                    // new line means end of section
                    if textRemainder.starts(with: "\n") {
                        advanceIfPossible(after: i)
                        break
                    }
                    
                    guard let itemStartIndex = textRemainder.firstIndex(of: "-") else {
                        guard !foodItems.isEmpty else {
                            printErrorPosition()
                            throw Error.expectedFoodItem
                        }
                        break
                    }
                    advanceIfPossible(after: itemStartIndex)
                    
                    eatWhitespaces()
                    guard let itemNameSeparator = textRemainder.firstIndex(of: ",") else {
                        printErrorPosition()
                        throw Error.expectedCalorieValue
                    }
                    let itemName = String(textRemainder[i..<itemNameSeparator]).trimmingCharacters(in: .whitespaces)
                    advanceIfPossible(after: itemNameSeparator)
                    
                    let quantityValue: Float, measurement: EntryEntity.QuantityMeasurement
                    let itemEndOfLine = textRemainder.firstIndex(of: "\n") ?? endIndex
                    let commasCount = textRemainder[i..<itemEndOfLine].filter { $0 == "," }.count
                    if commasCount > 0 { // optionally parse quantity
                        eatWhitespaces()
                        guard let itemQuantitySeparator = textRemainder.firstIndex(of: ",") else {
                            printErrorPosition()
                            throw Error.expectedCalorieValue
                        }
                        let itemQuantityString = String(textRemainder[i..<itemQuantitySeparator]).trimmingCharacters(in: .whitespaces)
                        advanceIfPossible(after: itemQuantitySeparator)
                        
                        // finalise item
                        guard let (_quantityValue, _measurement) = Self.getQuantity(text: itemQuantityString)
                        else {
                            printErrorPosition()
                            throw Error.invalidQuantity
                        }
                        quantityValue = _quantityValue
                        measurement = _measurement
                    } else {
                        quantityValue = 1
                        measurement = .portion
                    }
                    
                    eatWhitespaces()
                    let itemNewLine = textRemainder.firstIndex(of: "\n") ?? endIndex
                    var itemCalorieString = String(textRemainder[i..<itemNewLine]).trimmingCharacters(in: .whitespaces)
                    guard itemCalorieString.contains(" kcal") else {
                        printErrorPosition()
                        throw Error.invalidCaloriesMissingKcal
                    }
                    itemCalorieString = String(itemCalorieString.dropLast(" kcal".count))
                    advanceIfPossible(after: itemNewLine)
                    
                    guard let caloriesValue = itemCalorieString.floatValue else {
                        printErrorPosition()
                        throw Error.invalidCalories
                    }
                    
                    let foodItem = EntryEntity.Item(
                        title: itemName,
                        quantity: quantityValue,
                        measurement: measurement,
                        calories: caloriesValue
                    )
                    foodItems.append(foodItem)
                }
                
                // finalise section
                let section = EntryEntity.Section(
                    id: sectionName,
                    items: foodItems
                )
                sections.append(section)
                
                eatWhitespaces()
                if textRemainder[i..<endIndex].starts(with: "Total: ") {
                    if let newLineAfterTotal = textRemainder.firstIndex(of: "\n") {
                        advanceIfPossible(after: newLineAfterTotal)
                        eatWhitespaces()
                        advanceIfPossible(after: i)
                    } else {
                        advanceIfPossible(after: endIndex)
                    }
                    break
                }
            }
            
            // finalise entry
            let entry = EntryEntity(
                date: dateString,
                sections: sections
            )
            entries.append(entry)
            
            eatWhitespacesAndNewlines()
        }
        
        return entries
    }
    
    static func getQuantity(text: String) -> (Float, EntryEntity.QuantityMeasurement)? {
        if let quantityValue = text.floatValue {
            return (quantityValue, .portion)
        }
        
        for measurement in EntryEntity.QuantityMeasurement.allCases {
            let acceptableValues = switch measurement {
            case .liter: ["milliliter", "millilitre", "liter", "litre", "ml", "l"]
            case .kilogram: ["kilogram", "gram", "kg", "gr", "g"]
            case .cup: ["cup"]
            case .portion: ["portion", "part"]
            }
            
            let subdivisionValues = [
                "gram", "gr", "g", "milliliter", "millilitre", "ml"
            ]
            
            for value in acceptableValues {
                guard text.hasSuffix(value) else { continue }
                let textWithoutSuffix = String(text.dropLast(value.count)).trimmingCharacters(in: .whitespaces)
                guard let quantityValue = textWithoutSuffix.floatValue else { return nil }
                let subdivision: Float = subdivisionValues.contains(value) ? 1000.0 : 1
                return (quantityValue / subdivision, measurement)
            }
        }
        return nil
    }
}
