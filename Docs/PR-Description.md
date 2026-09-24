# Complete seed-manual workflow and assessment documentation

PulseFix previously referenced missing TXT seeds and could accept grounded model responses without usable citations. This change bundles the five supplied training PDFs, imports missing seeds on launch, derives citation metadata from local source IDs, and rejects incomplete safety evidence before presenting actionable results.

Application orchestration now uses a Domain repository contract and diagnosis use case. The UI displays a draft summary during streaming, localized trace/error labels, and response timing metrics. Delivery resources include `.env` setup, architecture and sequence diagrams, two ADRs, manual acceptance checks and a simulator build/resource CI workflow.

## Validation

- Five original PDFs inspected: 15 extractable pages, safety prerequisites and page numbering present.
- Static resource/localization validation passed.
- All Swift sources passed an iOS SDK type check in the restricted local session.
- Full Xcode builds were blocked by unavailable CoreSimulator services during asset compilation; no successful device run or hosted CI run is claimed.
- Unit tests and videos excluded by owner instruction.

## Review focus

Review conservative lexical safety checks and bilingual retrieval limits. Verify clean-install seed import, exact source-page navigation, AR/EN switching and human approval on an iOS 26 device/simulator.
