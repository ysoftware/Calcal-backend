import Foundation

@main struct App {
    static func main() {
        let parser = Parser(text: """
                            Date: 1 April, 2024

                            Breakfast
                            - Cappuccino, 1, 45 kcal

                            Total: 45 kcal
                            """)
        let result = try! parser.parse()
        print("\(result)")
    }
}
