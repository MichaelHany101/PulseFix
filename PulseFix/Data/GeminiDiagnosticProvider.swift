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
    private let model = "gemini-2.5-flash"

    init(session: URLSession = .shared, apiKey: String? = nil) {
        self.session = session
        self.apiKey = apiKey ?? (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? "")
    }

    func streamDiagnosis(query: String, evidence: [RetrievedChunk], language: AppLanguage) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !apiKey.isEmpty, apiKey != "YOUR_GEMINI_API_KEY" else { throw PulseFixError.missingAPIKey }
                    let prompt = buildPrompt(query: query, evidence: evidence, language: language)
                    let request = try makeRequest(prompt: prompt)
                    let (bytes, response) = try await session.bytes(for: request)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw PulseFixError.invalidResponse }
                    var assembled = ""
                    for try await line in bytes.lines where line.hasPrefix("data: ") {
                        let json = String(line.dropFirst(6))
                        guard let data = json.data(using: .utf8),
                              let envelope = try? JSONDecoder().decode(GeminiEnvelope.self, from: data),
                              let text = envelope.candidates.first?.content.parts.first?.text else { continue }
                        assembled += text
                        continuation.yield(.text(text))
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
        let encoded = apiKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? apiKey
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent?alt=sse&key=\(encoded)")!
        var request = URLRequest(url: url); request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [.init(parts: [.init(text: prompt)])]))
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
        return try JSONDecoder().decode(DiagnosticResult.self, from: data)
    }
}

private struct GeminiRequest: Encodable { let contents: [Content]; struct Content: Encodable { let parts: [Part] }; struct Part: Encodable { let text: String } }
private struct GeminiEnvelope: Decodable { let candidates: [Candidate]; struct Candidate: Decodable { let content: Content }; struct Content: Decodable { let parts: [Part] }; struct Part: Decodable { let text: String? } }
