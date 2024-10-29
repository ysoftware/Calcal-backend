import Foundation
import Hummingbird

@main struct App {
    static func main() async throws {
        let router = Router()

        router.get("main.php") { request, _ -> String in
            print("got get: \(request)")

            let url = URL(fileURLWithPath: "data.txt")
            do { 
                let data = try Data(contentsOf: url)
                let contents = String(data: data, encoding: .utf8)
                return contents ?? "Error"
            } catch {
                return "\(error)"
            }
        }

        router.post("main.php") { request, _ -> String in
            print("got post: \(request)")
            return ""  
        }

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 7070))
        )
        try await app.runService()
    }
}
