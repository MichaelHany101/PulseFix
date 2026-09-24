# ADR 002 — Domain provider contract with Gemini REST adapter

Status: Accepted
Date: 2026-09-25

## Context

SwiftUI needs incremental responses while Domain must remain independent of UI and LLM SDKs. Provider transport may change and responses must be checked before creating an actionable work-order draft.

## Decision

Expose `DiagnosticProviding` and `StreamEvent` from Domain. Inject the concrete Gemini adapter at composition. The adapter uses URLSession REST SSE, supplies a JSON response schema, reports request-size metadata and text fragments, and produces a final DiagnosticResult. The Domain use case owns grounding and safety result validation. AppModel owns presentation state and stream performance metrics.

## Alternatives and tradeoffs

Direct API calls in views would couple UI to transport and prevent substitution. An SDK is unnecessary for the narrow REST surface. Full JSON decoding waits until completion; a presentation parser extracts the summary string incrementally and labels it as a draft. Provider-specific errors remain in the Data adapter and are localized for the selected language.

## Credentials and cancellation

The ignored local `.env` is converted by a non-executing configuration script into ignored Xcode settings. No API key is committed. This follows the assignment's client-only constraint, so the built app still contains its configured credential. A language revision prevents stale results from entering UI state. The provider cancels its task when the stream terminates. Automatic retries are not part of this decision.
