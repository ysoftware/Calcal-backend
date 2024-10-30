import Foundation
import Hummingbird
import MultipartKit

struct PostBody: Decodable {
    let file: String
    let password: String
}

@main struct App {
    static func main() async throws {
        let router = Router()

        router.get("main.php") { request, _ -> String in
            print("got get")

            do {
                let url = URL(fileURLWithPath: "data.txt")
                let data = try Data(contentsOf: url)
                let contents = String(data: data, encoding: .utf8)
                return contents ?? "Error"
            } catch {
                return "\(error)"
            }
        }

        router.post("main.php") { request, context -> Response in
            guard let contentType = request.headers[.contentType],
                  let mediaType = MediaType(from: contentType),
                  let parameter = mediaType.parameter,
                  parameter.name == "boundary"
            else { return Response(status: .badRequest, headers: HTTPFields(), body: ResponseBody()) }

            let postBody: PostBody
            do {
                let buffer = try await request.body.collect(upTo: context.maxUploadSize)
                postBody = try FormDataDecoder().decode(PostBody.self, from: buffer, boundary: parameter.value)
            } catch {
                print("got post: bad request \(#line)")
                return Response(status: .badRequest, headers: HTTPFields(), body: ResponseBody())
            }

            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: "password.txt"))
                guard let password = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    print("got post: server error \(#line)")
                    return Response(status: .internalServerError, headers: HTTPFields(), body: ResponseBody())
                }
                
                if postBody.password != password {
                    print("got post: forbidden \(#line)")
                    return Response(status: .forbidden, headers: HTTPFields(), body: ResponseBody())
                }
            } catch {
                print("got post: server error \(#line)")
                return Response(status: .internalServerError, headers: HTTPFields(), body: ResponseBody())
            }

            var newData: [EntryEntity]
            do {
                newData = try Parser(text: postBody.file).parse()
            } catch {
                print("got post: bad request \(#line)")
                return Response(status: .badRequest, headers: HTTPFields(), body: ResponseBody())
            }

            var existingData: [EntryEntity] = []
            do {
                if let data = try? Data(contentsOf: URL(fileURLWithPath: "data.txt")), 
                    let contents = String(data: data, encoding: .utf8) {
                    existingData = try Parser(text: contents).parse()
                }
            } catch {
                print("got post: server error \(#line)")
                return Response(status: .internalServerError, headers: HTTPFields(), body: ResponseBody())
            }

            for entry in newData {
                if let foundIndex = existingData.firstIndex(where: { $0.date == entry.date }) {
                    existingData[foundIndex] = entry
                } else {
                    existingData.append(entry)
                }
            }

            guard let data = existingData.map(Mapper.map(entity:)).joined(separator: "\n\n").data(using: .utf8)
            else { 
                print("got post: server error \(#line)")
                return Response(status: .internalServerError, headers: HTTPFields(), body: ResponseBody())
            }

            do {
                try data.write(to: URL(fileURLWithPath: "data.txt"))
            } catch {
                print("got post: server error \(#line)")
                return Response(status: .internalServerError, headers: HTTPFields(), body: ResponseBody())
            }

            print("got post: ok")
            return Response(status: .ok, headers: HTTPFields(), body: ResponseBody())
        }

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 8000))
        )
        try await app.runService()
    }
}
