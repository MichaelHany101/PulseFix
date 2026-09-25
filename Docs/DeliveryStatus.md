# Delivery status

Updated: 2026-09-26

## Included in this change

- Five original three-page simulated PDF seed manuals, automatic idempotent import.
- Domain diagnosis use case and repository abstraction with a SwiftData adapter.
- Canonical page citations, nonempty grounded citations, conservative safety gates and refusal normalization.
- Arabic/English UI event/error labels, expanded domain search vocabulary, explicit equipment-code scope.
- Draft summary streaming and first-text/total-time/character-throughput metrics.
- Local `.env` setup with ignored generated Xcode settings.
- README, architecture boundaries, layer and sequence diagrams, two ADRs.
- Domain, local search and AppModel unit tests using mock LLM responses; CI runs these before the existing build/resource checks, without API credentials.
- Product demo and teaching sample Google Drive links in README.

## External verification required

The owner will handle GitHub publication, visibility and pull requests. The unauthenticated repository URL returned 404 during review, so public visibility is not confirmed. Both Google Drive links opened without requiring sign-in on 2026-09-26, but Drive had not completed reliable browser playback at verification time. Recheck playback before submission. Hosted CI results and Gemini account free-tier eligibility require account verification. The observed local history before this change contained 28 commits over five dates and merges for PRs #1–#3. Do not create artificial/backdated commits to meet counts.

## Unit-test verification

The suite has been simplified at the owner's request to six beginner tests across Domain, local search and AppModel. Advanced regression coverage was removed. See [UnitTests.md](UnitTests.md) for scope and execution instructions.

## Local verification limits

The restricted desktop session cannot access CoreSimulator's runtime service; full Xcode builds encounter asset catalog runtime errors. All Swift files passed an iOS 26 SDK type check with the project’s MainActor default. PDFKit extraction and ten English/Arabic retrieval probes included the matching troubleshooting page and passed the conservative evidence gate. Static resources/localization checks passed, and the build resource phase copied all five PDFs. These probes used page-level extracted text; device ingestion/layout remain part of acceptance. A device/simulator acceptance run and a green hosted CI result are still required before claiming full runtime verification.
