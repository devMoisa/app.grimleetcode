import Foundation

struct GrinLeetAPI {
    var baseURL: URL

    static let `default` = GrinLeetAPI(baseURL: URL(string: "http://127.0.0.1:8000")!)

    // MARK: - Public API

    func generateProblem(
        prompt: String,
        difficulty: Difficulty,
        topics: [String],
        model: String? = nil
    ) async throws -> Problem {
        let body = GenerateRequest(
            prompt: prompt,
            difficulty: difficulty.rawValue,
            topics: topics,
            model: model
        )
        let response: GenerateResponse = try await post(path: "generate", body: body)
        return response.problem.toDomain()
    }

    func health() async throws -> HealthResponse {
        try await get(path: "health")
    }

    // MARK: - Wire types

    private struct GenerateRequest: Encodable {
        let prompt: String
        let difficulty: String
        let topics: [String]
        let model: String?
    }

    private struct GenerateResponse: Decodable {
        let problem: ProblemDTO
        let model: String
    }

    private struct ProblemDTO: Decodable {
        let title: String
        let difficulty: String
        let tags: [String]
        let statement: String
        let examples: [ExampleDTO]
        let constraints: [String]

        func toDomain() -> Problem {
            Problem(
                id: UUID(),
                title: title,
                difficulty: Difficulty(rawValue: difficulty) ?? .medium,
                tags: tags,
                statement: statement,
                examples: examples.map {
                    Problem.Example(input: $0.input, output: $0.output, explanation: $0.explanation)
                },
                constraints: constraints,
                createdAt: Date()
            )
        }
    }

    private struct ExampleDTO: Decodable {
        let input: String
        let output: String
        let explanation: String?
    }

    struct HealthResponse: Decodable {
        let status: String
        let model: String
    }

    // MARK: - Error

    enum APIError: LocalizedError {
        case invalidResponse
        case httpStatus(Int, String)
        case decodingFailed(Error)
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                "Backend returned an unexpected response."
            case .httpStatus(let code, let message):
                "Backend error \(code): \(message)"
            case .decodingFailed(let err):
                "Could not parse backend response: \(err.localizedDescription)"
            case .transport(let err):
                "Cannot reach backend: \(err.localizedDescription)"
            }
        }
    }

    // MARK: - Transport

    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    private func get<Response: Decodable>(path: String) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        return try await send(request)
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = Self.extractError(from: data)
                ?? String(data: data, encoding: .utf8)
                ?? "no body"
            throw APIError.httpStatus(http.statusCode, message)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    private static func extractError(from data: Data) -> String? {
        struct FastAPIError: Decodable { let detail: String? }
        return (try? JSONDecoder().decode(FastAPIError.self, from: data))?.detail
    }
}
