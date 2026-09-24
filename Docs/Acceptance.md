# Manual acceptance checklist

No unit-test suite is included in this change, as requested by the owner. These are reproducible manual checks, not claims that device verification has already passed.

- Fresh install: five manuals, each with three pages, appear without manual import.
- Relaunch: five seeds remain, no duplicate seed imports. Import a sixth PDF/TXT and relaunch; it remains.
- Run each English/Arabic pair in README. Matching equipment's troubleshooting page should appear among retrieved results, citations should open the correct PDF page.
- Import two different PDFs with the same filename; citations must still resolve through chunk/manual IDs.
- Query `quasarflux unobtainium`: show insufficient evidence without an API request.
- Import a relevant TXT with symptoms but no explicit safety block: refuse diagnosis when it is the only retrieved evidence.
- English → Arabic → English on every tab and sheet: titles, badges, metrics, errors and direction update. Imported/source text and human-authored text retain their original language.
- Switch languages during a response: the old response must not repopulate the result.
- Streaming: only a draft summary, not JSON keys, is shown. Final actions appear after completion and validation.
- Citation source ID outside evidence or empty citations in a grounded result must be rejected. Returned names/page numbers are replaced from local evidence.
- Final negative status or missing safety list must not expose repair steps/work order approval.
- Approve, edit and reject separate drafts; verify each saved decision and note after relaunch.
- Trace screen: prompt characters, response characters, first-text latency, total time and throughput are populated after a successful request.
- Disable network: existing manuals/work orders remain accessible; diagnosis shows a localized failure.
- CI: simulator build and five-resource bundle check pass on GitHub after publication.
