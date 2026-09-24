//
//  GeminiDiagnosticProvider.swift
//  PulseFix
//
//  Created by Michael Hany on 23/09/2026.
//

import Foundation

struct GeminiDiagnosticProvider: DiagnosticProviding {
    private let session: URLSession
    private let apiKey: String
    private let model = "gemini-3.6-flash"

    init(session: URLSession = .shared, apiKey: String? = nil) {
        self.session = session
        self.apiKey = (apiKey ?? (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func streamDiagnosis(query: String, evidence: [RetrievedChunk], language: AppLanguage) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !apiKey.isEmpty, apiKey != "YOUR_GEMINI_API_KEY", !apiKey.contains("$(") else { throw PulseFixError.missingAPIKey }
                    let prompt = buildPrompt(query: query, evidence: evidence, language: language)
                    let request = try makeRequest(prompt: prompt)
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else { throw PulseFixError.invalidResponse }
                    guard (200..<300).contains(http.statusCode) else {
                        var body = Data()
                        for try await byte in bytes {
                            if body.count >= 65_536 { break }
                            body.append(byte)
                        }
                        let message = (try? JSONDecoder().decode(GeminiEnvelope.self, from: body))?.error?.message
                        throw GeminiServiceError(message: "Gemini HTTP \(http.statusCode): \(message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode))")
                    }
                    var assembled = ""
                    for try await line in bytes.lines where line.hasPrefix("data:") {
                        let json = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if json == "[DONE]" { continue }
                        let envelope = try JSONDecoder().decode(GeminiEnvelope.self, from: Data(json.utf8))
                        if let error = envelope.error { throw GeminiServiceError(message: error.message) }
                        if let reason = envelope.promptFeedback?.blockReason {
                            throw GeminiServiceError(message: "Gemini blocked the request: \(reason)")
                        }
                        guard let candidate = envelope.candidates?.first else { continue }
                        if let reason = candidate.finishReason, reason != "STOP" {
                            throw GeminiServiceError(message: "Gemini stopped before completing the response: \(reason)")
                        }
                        for part in candidate.content?.parts ?? [] where part.thought != true {
                            guard let text = part.text else { continue }
                            assembled += text
                            continuation.yield(.text(text))
                        }
                    }
                    guard !assembled.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw GeminiServiceError(message: "Gemini returned no answer text.")
                    }
                    let result = try decodeResult(from: assembled)
                    let allowed = Set(evidence.map(\.chunk.id))
                    guard result.citations.allSatisfy({ allowed.contains($0.sourceID) }) else { throw PulseFixError.ungroundedCitation }
                    continuation.yield(.completed(result)); continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func makeRequest(prompt: String) throws -> URLRequest {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent?alt=sse")!
        var request = URLRequest(url: url); request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["responseMimeType": "application/json", "responseJsonSchema": Self.resultSchema]
        ])
        return request
    }

    private func buildPrompt(query: String, evidence: [RetrievedChunk], language: AppLanguage) -> String {
        let context = evidence.map { "SOURCE_ID: \($0.chunk.id)\nMANUAL: \($0.chunk.manualName)\nPAGE: \($0.chunk.pageNumber)\nTEXT: \($0.chunk.content)" }.joined(separator: "\n---\n")
        return """
        You are PulseFix, an industrial maintenance diagnostic copilot. Answer in \(language == .arabic ? "Arabic" : "English").
        Use ONLY the supplied evidence. Never invent facts, parts, steps, or citations.
        If evidence is insufficient, status must be insufficient_evidence and summary must say \(language == .arabic ? "المعلومات غير كافية في الأدلة المتاحة" : "Not enough information in manuals").
        If safety isolation, lockout, PPE, or prerequisites are absent, status must be missing_safety_prerequisites and do not provide repair steps.
        Return JSON only with: status, summary, safetyPrerequisites, recommendedActions, citations [{sourceID,manualName,pageNumber}], workOrder {title,equipment,priority,steps} or null.
        QUERY: \(query)
        EVIDENCE:\n\(context)
        """
    }

    private func decodeResult(from value: String) throws -> DiagnosticResult {
        let clean = value.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = clean.data(using: .utf8) else { throw PulseFixError.invalidResponse }
        do { return try JSONDecoder().decode(DiagnosticResult.self, from: data) }
        catch { throw GeminiServiceError(message: "Gemini returned an answer that did not match the diagnostic format. Please retry.") }
    }
}

private struct GeminiServiceError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private struct GeminiEnvelope: Decodable {
    let candidates: [Candidate]?
    let error: APIError?
    let promptFeedback: Feedback?
    struct APIError: Decodable { let message: String }
    struct Feedback: Decodable { let blockReason: String? }
    struct Candidate: Decodable { let content: Content?; let finishReason: String? }
    struct Content: Decodable { let parts: [Part]? }
    struct Part: Decodable { let text: String?; let thought: Bool? }
}

extension GeminiDiagnosticProvider {
    private static var resultSchema: [String: Any] {
        let string: [String: Any] = ["type": "string"]
        let strings: [String: Any] = ["type": "array", "items": string]
        return [
            "type": "object",
            "required": ["status", "summary", "safetyPrerequisites", "recommendedActions", "citations", "workOrder"],
            "properties": [
                "status": ["type": "string", "enum": ["grounded", "insufficient_evidence", "missing_safety_prerequisites"]],
                "summary": string,
                "safetyPrerequisites": strings,
                "recommendedActions": strings,
                "citations": ["type": "array", "items": [
                    "type": "object", "required": ["sourceID", "manualName", "pageNumber"],
                    "properties": ["sourceID": string, "manualName": string, "pageNumber": ["type": "integer"]]
                ]],
                "workOrder": ["type": ["object", "null"], "required": ["title", "equipment", "priority", "steps"],
                              "properties": ["title": string, "equipment": string, "priority": string, "steps": strings]]
            ]
        ]
    }
}
