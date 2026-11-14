#!/usr/bin/env python3
"""Dreiwege-Merge für Localizable.xcstrings (JSON): beide Seiten behalten.
Aufruf bei Merge-Konflikt im Repo-Wurzelordner: python3 Werkzeug/xcstrings-merge.py App/Ressourcen/Localizable.xcstrings
Je Schlüssel: nur eine Seite geändert -> diese; beide geändert -> Lokalisierungen vereinigt (bei gleicher Sprache gewinnt „theirs“)."""
import json, subprocess, sys
pfad = sys.argv[1]
def stufe(n):
    r = subprocess.run(["git", "show", f":{n}:{pfad}"], capture_output=True, text=True)
    return json.loads(r.stdout) if r.returncode == 0 and r.stdout.strip() else {"strings": {}}
base, ours, theirs = stufe(1), stufe(2), stufe(3)
out = json.loads(json.dumps(ours))
b, o, t = base.get("strings", {}), ours.get("strings", {}), theirs.get("strings", {})
konflikte = 0
for k in set(b) | set(o) | set(t):
    if k in o and k in t:
        if o[k] == t[k]: continue
        if b.get(k) == o[k]: out["strings"][k] = t[k]
        elif b.get(k) == t[k]: out["strings"][k] = o[k]
        else:
            konflikte += 1
            m = json.loads(json.dumps(o[k])); loc = m.setdefault("localizations", {})
            loc.update(t[k].get("localizations", {})); out["strings"][k] = m
    elif k in t and k not in b: out["strings"][k] = t[k]          # neu in theirs
    elif k in t and k not in o: pass                                # ours hat gelöscht
    elif k in o and k not in t and k in b: out["strings"].pop(k, None)  # theirs hat gelöscht
open(pfad, "w").write(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
print("zusammengeführt, Schlüssel:", len(out["strings"]), "– beidseitig geänderte:", konflikte)
