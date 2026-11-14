#!/usr/bin/env python3
"""Bauplan T3 / Blatt 27: neuer Text „Stapel · %lld“ (Rommé, breiter Tintentisch) in vier Sprachen."""
import json, pathlib
p = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
d = json.loads(p.read_text(encoding="utf-8"))
t = {"de": "Stapel · %lld", "en": "Stock · %lld", "es": "Mazo · %lld", "fr": "Talon · %lld"}
d["strings"]["Stapel · %lld"] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in t.items()}}
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
