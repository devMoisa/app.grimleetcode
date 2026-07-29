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

    func runCode(
        language: ProgrammingLanguage,
        code: String,
        stdin: String = "",
        timeoutSeconds: Double = 10
    ) async throws -> ExecutionResult {
        let body = RunRequest(
            language: language.rawValue,
            code: code,
            stdin: stdin,
            timeout_seconds: timeoutSeconds
        )
        let response: RunResponse = try await post(path: "run", body: body)
        return response.toExecutionResult()
    }

    func verifyCode(
        problem: Problem,
        language: ProgrammingLanguage,
        code: String
    ) async throws -> ExecutionResult {
        let body = VerifyRequest(
            problem: VerifyProblemDTO(from: problem),
            language: language.rawValue,
            code: code,
            model: nil
        )
        let response: VerifyResponse = try await post(path: "verify", body: body)
        return response.toExecutionResult()
    }

    func transcribe(audioURL: URL, language: String? = "pt") async throws -> String {
        let boundary = "GrinLeet-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appendingPathComponent("transcribe"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        var body = Data()
        let filename = audioURL.lastPathComponent
        let mime = Self.mimeType(for: audioURL)
        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
        } catch {
            throw APIError.transport(error)
        }

        body.appendMultipartField(
            boundary: boundary,
            name: "file",
            filename: filename,
            contentType: mime,
            data: audioData
        )
        if let language {
            body.appendMultipartTextField(boundary: boundary, name: "language", value: language)
        }
        body.appendMultipartClosing(boundary: boundary)
        request.httpBody = body

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = Self.extractError(from: data)
                ?? String(data: data, encoding: .utf8)
                ?? "no body"
            throw APIError.httpStatus(http.statusCode, message)
        }

        let decoded: TranscribeResponse
        do {
            decoded = try JSONDecoder().decode(TranscribeResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
        return decoded.text
    }

    private struct TranscribeResponse: Decodable {
        let text: String
        let model: String
        let duration_ms: Int
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "m4a", "mp4": "audio/m4a"
        case "wav": "audio/wav"
        case "mp3": "audio/mpeg"
        case "caf": "audio/x-caf"
        case "aif", "aiff": "audio/aiff"
        default: "application/octet-stream"
        }
    }

    func chat(
        problem: Problem,
        history: [ChatMessage]
    ) async throws -> ChatMessage {
        let body = ChatBody(
            problem: VerifyProblemDTO(from: problem),
            messages: history.map { ChatMessageDTO(role: $0.role.rawValue, content: $0.content) },
            model: nil
        )
        let response: ChatResponseDTO = try await post(path: "chat", body: body)
        return ChatMessage(
            role: .assistant,
            content: response.message.content
        )
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

    private struct RunRequest: Encodable {
        let language: String
        let code: String
        let stdin: String
        let timeout_seconds: Double
    }

    private struct VerifyRequest: Encodable {
        let problem: VerifyProblemDTO
        let language: String
        let code: String
        let model: String?
    }

    private struct VerifyProblemDTO: Encodable {
        let title: String
        let difficulty: String
        let tags: [String]
        let statement: String
        let examples: [VerifyExampleDTO]
        let constraints: [String]

        init(from problem: Problem) {
            self.title = problem.title
            self.difficulty = problem.difficulty.rawValue
            self.tags = problem.tags
            self.statement = problem.statement
            self.examples = problem.examples.map {
                VerifyExampleDTO(input: $0.input, output: $0.output, explanation: $0.explanation)
            }
            self.constraints = problem.constraints
        }
    }

    private struct VerifyExampleDTO: Encodable {
        let input: String
        let output: String
        let explanation: String?
    }

    private struct VerifyResponse: Decodable {
        let passed: Bool
        let verdict: String
        let analysis: String
        let examples: [ExampleVerdictDTO]
        let edge_cases: [String]
        let model: String

        func toExecutionResult() -> ExecutionResult {
            var stdoutLines: [String] = []

            if !examples.isEmpty {
                stdoutLines.append("Per-example verdicts:")
                for ev in examples {
                    let mark = ev.passed ? "✓" : "✗"
                    stdoutLines.append("  \(mark) Example \(ev.example_index): \(ev.reasoning)")
                    if !ev.passed {
                        stdoutLines.append("      expected: \(ev.expected)")
                        stdoutLines.append("      predicted: \(ev.predicted)")
                    }
                }
                stdoutLines.append("")
            }

            stdoutLines.append("Analysis:")
            stdoutLines.append(analysis)

            if !edge_cases.isEmpty {
                stdoutLines.append("")
                stdoutLines.append("Edge cases to consider:")
                for ec in edge_cases {
                    stdoutLines.append("  • \(ec)")
                }
            }

            stdoutLines.append("")
            stdoutLines.append("Judged by \(model).")

            return ExecutionResult(
                status: passed ? .success : .failed,
                stdout: stdoutLines.joined(separator: "\n"),
                stderr: "",
                verdict: verdict,
                executionTimeMs: nil
            )
        }
    }

    private struct ExampleVerdictDTO: Decodable {
        let example_index: Int
        let passed: Bool
        let expected: String
        let predicted: String
        let reasoning: String
    }

    private struct ChatBody: Encodable {
        let problem: VerifyProblemDTO
        let messages: [ChatMessageDTO]
        let model: String?
    }

    private struct ChatMessageDTO: Codable {
        let role: String
        let content: String
    }

    private struct ChatResponseDTO: Decodable {
        let message: ChatMessageDTO
        let model: String
    }

    private struct RunResponse: Decodable {
        let stdout: String
        let stderr: String
        let exit_code: Int
        let duration_ms: Int
        let timed_out: Bool
        let compile_error: String?

        func toExecutionResult() -> ExecutionResult {
            let status: ExecutionResult.Status
            if compile_error != nil {
                status = .error
            } else if timed_out {
                status = .error
            } else if exit_code == 0 {
                status = .success
            } else {
                status = .failed
            }

            var combinedStderr = stderr
            if let ce = compile_error, !ce.isEmpty {
                let sep = combinedStderr.isEmpty ? "" : "\n\n"
                combinedStderr = "Compile error:\n\(ce)\(sep)\(combinedStderr)"
            }

            var verdict: String?
            if timed_out {
                verdict = "Timed out after \(duration_ms) ms."
            } else if exit_code != 0 && compile_error == nil {
                verdict = "Exited with code \(exit_code)."
            }

            return ExecutionResult(
                status: status,
                stdout: stdout,
                stderr: combinedStderr,
                verdict: verdict,
                executionTimeMs: duration_ms
            )
        }
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
