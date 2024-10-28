import Foundation

final class Model: @unchecked Sendable {
    
    /// load data once, update locally, never save to backend
    static let TEST_DATA_NEVER_UPLOAD = false
    
    /// use another backend url
    static let TEST_DATA_CHANGES_LOCAL_BACKEND = false

    private var data: [EntryEntity] = []
    
    func appendItem(item: EntryEntity.Item, destination: ItemDestination) async throws {
        assert(!destination.entryId.isEmpty)
        assert(!destination.sectionId.isEmpty)
        
        guard var entry = getAllEntries().first(where: { $0.date == destination.entryId }) else { return }
        
        if entry.sections.firstIndex(where: { $0.id == destination.sectionId }) == nil {
            entry.sections.append(EntryEntity.Section(id: destination.sectionId, items: []))
        }
        
        guard let sectionIndex = entry.sections.firstIndex(where: { $0.id == destination.sectionId })
        else { return assertionFailure("the section must have been added") }
        
        entry.sections[sectionIndex].items.append(item)
        
        try await addOrUpdateEntry(entry: entry)
        try await saveModel()
    }
    
    func addOrUpdateEntry(entry: EntryEntity) async throws {
        if let entryIndex = data.firstIndex(where: { $0.date == entry.date }) {
            data[entryIndex] = entry
        } else {
            data.append(entry)
        }
        try await saveModel()
    }
    
    func getAllEntries() -> [EntryEntity] {
        data
    }
    
    // MARK: - Work with Storage
    
    private var apiUrl: URL {
        if Self.TEST_DATA_CHANGES_LOCAL_BACKEND {
            URL(string: "http://192.168.178.30:8000/main.php")!
        } else {
            URL(string: "http://185.163.118.53:80/main.php")!
        }
    }
    
    func fetchModel() async throws {
        if Self.TEST_DATA_NEVER_UPLOAD {
            // loads data once
            if !self.data.isEmpty { return }
        }
        
        print("Fetching data from \(self.apiUrl)...")
        
        let (data, response) = try await URLSession.shared.data(from: apiUrl)
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { return }
        guard statusCode == 200, let contents = String(data: data, encoding: .utf8)
        else { throw Error.invalidResponse(code: statusCode) }
        
        let entities = try Parser(text: contents).parse()
        self.data = entities
    }
    
    func deleteItem(entryId: String, sectionId: String, itemIndex: Int) async throws {
        guard let entryIndex = data.firstIndex(where: { $0.date == entryId }),
              let sectionIndex = data[entryIndex].sections.firstIndex(where: { $0.id == sectionId }),
              data[entryIndex].sections[sectionIndex].items.count > itemIndex
        else { return }
        
        data[entryIndex].sections[sectionIndex].items.remove(at: itemIndex)
        
        if data[entryIndex].sections[sectionIndex].items.isEmpty {
            data[entryIndex].sections.remove(at: sectionIndex)
        }
        
        try await saveModel()
    }
    
    private func saveModel() async throws {
        if Self.TEST_DATA_NEVER_UPLOAD {
            return
        }
        
        print("Saving data from \(self.apiUrl)...")
        
        let content = data
            .map(Mapper.map(entity:))
            .joined(separator: "\n\n")
        
        guard let url = Bundle.main.url(forResource: "password", withExtension: "txt") else { return }
        let password = try String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // file content
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"text.txt\"\r\n")
        body.append("Content-Type: text/plain\r\n\r\n")
        body.append(content)
        body.append("\r\n")
        
        // password
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"password\"\r\n")
        body.append("Content-Type: text/plain\r\n\r\n")
        body.append(password)
        body.append("\r\n")
        
        body.append("--\(boundary)--\r\n")
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { return }
        
        if statusCode != 200 {
            let dump = String(data: data, encoding: .utf8) ?? ""
            print("\(dump)")
            throw Error.invalidResponse(code: statusCode)
        }
    }
    
    enum Error: Swift.Error {
        case invalidResponse(code: Int)
    }
}

struct ItemDestination {
    let entryId: String
    let sectionId: String
}

private extension Data {
    mutating func append(_ value: String) {
        guard let stringData = value.data(using: .utf8) else { return }
        
        stringData.withUnsafeBytes { bytes in
            self.append(contentsOf: bytes)
        }
    }
}
