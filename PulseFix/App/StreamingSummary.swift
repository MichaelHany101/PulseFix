import Foundation

/// Extracts only the JSON summary string while the complete object is still arriving.
/// Escaped characters are decoded by JSONDecoder, never displayed as JSON syntax.
struct StreamingSummary {
    static func extract(from json: String) -> String {
        guard let key = json.range(of: "\"summary\""),
              let colon = json[key.upperBound...].firstIndex(of: ":") else { return "" }
        let suffix = json[json.index(after: colon)...].drop(while: { $0.isWhitespace })
        guard suffix.first == "\"" else { return "" }
        var escaped = false
        var encoded = "\""
        var latest = ""
        for character in suffix.dropFirst() {
            if character == "\"" && !escaped { return latest }
            encoded.append(character)
            if let data = (encoded + "\"").data(using: .utf8), let value = try? JSONDecoder().decode(String.self, from: data) { latest = value }
            if character == "\\" && !escaped { escaped = true } else { escaped = false }
        }
        return latest
    }
}
