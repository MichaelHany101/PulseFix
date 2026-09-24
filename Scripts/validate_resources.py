#!/usr/bin/env python3
"""Static delivery checks; this is not a unit-test suite."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
manuals = list((root / "PulseFix/Resources/SeedManuals").glob("*.pdf"))
assert len(manuals) >= 5, "At least five seed manuals are required"
for manual in manuals:
    assert manual.read_bytes().startswith(b"%PDF-"), manual.name
catalog = json.loads((root / "PulseFix/Resources/Localizable.xcstrings").read_text())
for key, entry in catalog["strings"].items():
    if key == "• %@" or entry.get("shouldTranslate") is False:
        continue
    for language in ("en", "ar"):
        assert language in entry.get("localizations", {}), (key, language)
print(f"Validated {len(manuals)} PDF resources and bilingual catalog entries.")
