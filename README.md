# PulseFix

An iOS training diagnostic copilot using local manuals and the Gemini API, with no backend.

**Assessment choices:** D0 (Industrial Plant Maintenance) + T0 (Arabic / English).
**Stack:** SwiftUI, Observation, PDFKit, SwiftData, direct Gemini REST streaming.
**Requirements:** Xcode 26+, iOS 26+, Python 3 for local configuration. A Gemini API project with access to the configured model. Account billing/free-tier eligibility must be checked in Google AI Studio; the app cannot establish it.

## Run

1. Copy `.env.example` to `.env` at the repository root.
2. Set `GEMINI_API_KEY` in `.env` (do not commit this file).
3. Run `python3 Scripts/configure.py`. This generates ignored `Config/Secrets.xcconfig` from `.env`; no shell evaluation or key logging is used.
4. Open `PulseFix.xcodeproj`, select the PulseFix scheme and an iOS 26 simulator/device, then Run.
5. Five seed PDF manuals are imported automatically on launch. Subsequent launches skip already imported filenames. Import additional PDF/TXT documents using the plus button.
6. Select Arabic or English using the globe menu. Ask a question from the examples below. Review source citations before making an approval decision.

A missing local secrets file does not prevent compilation: shared `Config/Build.xcconfig` supplies a placeholder. Real API calls require configuration. API credentials reside in the installed client as required by the zero-backend assignment; `.gitignore` protects source control, not a distributed binary.

## Seed manuals and example queries

All five PDFs are **simulated training documents, not manufacturer instructions**. Each has three text-based pages: equipment identification, troubleshooting, and an authorized inspection procedure. Original PDFs are kept unchanged in `PulseFix/Resources/SeedManuals`.

| Manual | English query | Arabic query | Troubleshooting page |
|---|---|---|---|
| PX-200 pump | PX-200 high bearing temperature and vibration | ارتفاع حرارة مضخة PX-200 مع اهتزاز | 2 |
| AC-50 compressor | AC-50 low discharge pressure and air leak | انخفاض ضغط ضاغط AC-50 مع تسريب هواء | 2 |
| CV-10 conveyor | CV-10 belt drifts to one side | انحراف سير CV-10 إلى جانب واحد | 2 |
| BL-20 boiler | BL-20 burner flame failure | فشل لهب غلاية BL-20 | 2 |
| MT-75 motor | MT-75 unexpected trip and vibration | توقف محرك MT-75 مع اهتزاز | 2 |

## Workflow and safeguards

Local import → text extraction and page-based chunks → lexical bilingual search → conservative safety evidence gate → Gemini streamed JSON → canonical local citations and final validation → human approve/edit/reject → local persistence.

The visible stream is a **draft summary**, not raw JSON. Final actions and the approval button appear only after validation. A grounded answer needs nonempty citations and safety prerequisites. Reference filenames/pages are derived from local chunks, not trusted from model text. Refusals contain no repair steps or work-order draft. The safety gate requires an explicit safety block with isolation, lockout, zero-energy/verification and PPE cues for every represented manual. This is a conservative lexical gate, not a semantic proof of safety or factual correctness.

Manuals, chunks and work orders persist locally. Diagnosis responses, trace history and language selection are session state. Manual text is not automatically translated. The small bilingual vocabulary covers the supplied domain; arbitrary cross-language equivalence is not guaranteed. Scanned PDFs require OCR elsewhere: this app only extracts embedded text.

## Demo videos

- [Product Demo Video](https://drive.google.com/file/d/1I-juwhDzelAjh-up7bxgXY1PI65L8ERT/view?usp=sharing) — document ingestion, diagnostic flow, citations, approval gate and trace inspection.
- [Teaching Sample Video](https://drive.google.com/file/d/1VkChY-1JIsqi7nAtrko8pCrcAw89gtwu/view?usp=drive_link) — Clean Architecture and provider abstraction walkthrough.

## Documentation

- [Architecture and diagrams](Docs/Architecture.md)
- [ADR 001: Chunking and retrieval](Docs/ADR/001-local-retrieval.md)
- [ADR 002: Provider abstraction](Docs/ADR/002-provider-abstraction.md)
- [Manual acceptance checklist](Docs/Acceptance.md)
- [Delivery status](Docs/DeliveryStatus.md)
- [Unit tests: run, scope and test doubles](Docs/UnitTests.md)

## Build and CI

`python3 Scripts/validate_resources.py` checks the five PDF assets and bilingual string catalog.

```sh
xcodebuild -project PulseFix.xcodeproj -scheme PulseFix -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build-output CODE_SIGNING_ALLOWED=NO build
```

Run `swift test` from the repository root (Xcode 26 / Swift 6.2+). The Swift package compiles the original Domain, local search and AppModel files, and tests them with mock LLM responses on the Mac. No simulator or API key is needed for these unit tests. See [test instructions and scope](Docs/UnitTests.md).

GitHub Actions runs unit tests, resource validation, an unsigned simulator build, and checks that all five PDFs are in the built app. No real API key or live Gemini call is required by CI.

## Service errors

HTTP 503 means the provider is temporarily unavailable; try later or configure another supported model in `GeminiDiagnosticProvider.swift`. HTTP 429 indicates quota/rate limiting. Do not change credentials solely because of a 503. Automatic retry/fallback is not implemented. See [Google troubleshooting](https://ai.google.dev/gemini-api/docs/troubleshooting).
