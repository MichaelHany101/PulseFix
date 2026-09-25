# Architecture and design

## Boundaries

- **Domain:** Foundation-only data types, service contracts, repository contract, and `DiagnosisUseCase` (retrieval orchestration, refusal policy, canonical citations, result validation). No SwiftUI, SwiftData, PDFKit or Gemini SDK dependency.
- **Data:** PDFKit ingestion, lexical search, Gemini REST transport, SwiftData models and repository implementation. Implements Domain contracts.
- **Presentation / App:** SwiftUI screens and observable `AppModel`. The model depends on Domain service/repository contracts, and owns view state, language invalidation, request timing and progress. Views display state and send user intents.
- **Composition:** `PulseFixApp` constructs concrete ingestion/search/provider services. `RootView` binds the SwiftData repository from the environment context during startup. `WorkOrdersView` reads Domain work-order records from AppModel; both reads and writes go through the repository contract.

## Layer diagram (arrows mean depends on)

```mermaid
flowchart TD
    C[Composition: PulseFixApp and RootView] --> P[Presentation: SwiftUI and AppModel]
    C --> A[Data adapters]
    P --> D[Domain: entities, use case, contracts]
    A --> D
    A --> F[PDFKit / files]
    A --> S[SwiftData]
    A --> G[Gemini REST API]
```

## Data flow sequence diagram

```mermaid
sequenceDiagram
    actor User
    participant UI as SwiftUI
    participant App as AppModel
    participant Import as PDFTextIngestor
    participant Repo as ManualRepository
    participant Use as DiagnosisUseCase
    participant Search as LexicalChunkRetriever
    participant AI as GeminiDiagnosticProvider
    participant Cloud as Gemini API
    UI->>App: restore(repository), loadSeedManuals
    App->>Repo: load persisted manuals/chunks
    loop Each missing seed PDF or user import
        App->>Import: ingest local URL
        Import-->>App: manual + page-linked chunks
        App->>Repo: save manual/chunks
    end
    User->>UI: symptom + selected language
    UI->>App: diagnose
    App->>Use: retrieve(query, chunks)
    Use->>Search: top 5 matches
    Search-->>App: evidence
    App->>Use: safety evidence gate
    alt Missing evidence or incomplete prerequisites
        Use-->>UI: refusal, no work-order draft
    else Evidence accepted
        App->>AI: query + evidence + language
        AI->>Cloud: structured prompt and JSON schema
        loop Streaming events
            Cloud-->>AI: text fragments
            AI-->>App: response fragment
            App-->>UI: decoded draft summary + metrics
        end
        AI->>Use: validate result, resolve canonical citations
        Use-->>App: final validated result
        App-->>UI: result and source chips
        User->>UI: inspect PDF source page
        User->>UI: approve / edit / reject
        UI->>App: decision + reviewed draft + note
        App->>Repo: persist work order
        Repo-->>UI: saved order records refreshed in AppModel
    end
```

## State and identity

A language revision UUID invalidates responses after any language switch, including English → Arabic → English. Navigation is rebuilt for locale/direction updates. Generated results are cleared rather than silently translated. PDF lookup uses the cited chunk's manual UUID; names are display labels only.

## Storage and trust

PDF/TXT files are copied into Application Support/Manuals. SwiftData stores manual metadata, chunks and human work-order decisions. Saving fails atomically with repository rollback. Repeated startup does not reimport an existing seed filename. A safety gate is an evidence-format heuristic; human review remains required, and the app has no machinery-control capability or authenticated supervisor role.

The provider treats retrieved material as untrusted data in the prompt. It rejects unknown source IDs and derives reference metadata locally. Empty/unsupported grounded responses are rejected; negative statuses are normalized to refusal with no actions. Streaming summaries remain marked as draft until validation; they are not a verified diagnosis.

## Observability

Localized event labels, retrieved chunk count, full prompt character count (query + instructions + evidence, excluding transport JSON/schema), response character count, time to first text, total elapsed response time and average response characters/second are visible in Trace Inspector. Character throughput includes JSON transport text and total request latency; it is not model tokens/second. History is session-only.
