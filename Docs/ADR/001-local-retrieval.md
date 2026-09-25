# ADR 001 — Page-linked local chunks and lexical bilingual retrieval

Status: Accepted
Date: 2026-09-25

## Context

The assessment allows structured text matching or local vector search. Five small English training manuals must support Arabic and English questions without a backend. Exact PDF page citations must remain recoverable.

## Decision

Use PDFKit extraction page by page; group paragraphs around a 1,000-character target with 150-character overlap. A long paragraph can exceed the target, which preserves the supplied PDFs' complete safety blocks. Keep manual UUID, source ID and page number with every chunk. TXT is treated as one logical page.

Rank lexical term occurrences with a heading bonus. Expand a bounded bilingual maintenance vocabulary and normalize diacritics, case and basic Arabic articles. Explicit equipment codes constrain candidates to the matching seed manual. Return at most five positive-scoring chunks.

## Alternatives and tradeoffs

Embeddings would improve semantic recall but add model/runtime or network dependencies, storage and evaluation work. They are not required for the selected T0 variant. Lexical search is inspectable and offline, but synonyms outside the vocabulary and ambiguous symptom-only questions can miss or mix relevant material. Include equipment codes in demo questions. Chunk size is a target rather than a hard limit. No OCR is implemented.

## Validation

Resource validation confirms that all five original PDF files are present. The acceptance checklist covers bilingual paired queries and exact page navigation. No claim of general semantic equivalence is made.
