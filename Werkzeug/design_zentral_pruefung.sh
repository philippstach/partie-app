#!/bin/zsh
# Meldet feste Standard-Abstände/-Ecken und Hex-Farben, die nicht über Design.swift laufen.
# Widget-Ziel ist ausgenommen (kein KlarGlas dort). Spielinhalt (// design:spielinhalt, Dateien mit design:spielinhalt-datei) ist ausgenommen. Aufruf im Repo-Ordner.
cd "$(dirname "$0")/.." || exit 1
treffer=$(grep -rnE "spacing: *(4|8|12|16|24)\b[^.]|cornerRadius: *(8|12|20|28|32)\b[^.]|Color\(hex:|UIColor\(red" App Pakete --include='*.swift' --exclude-dir=.build 2>/dev/null \
  | grep -v "design:spielinhalt" | grep -v "Design\." | while IFS=: read -r f rest; do grep -q "design:spielinhalt-datei" "$f" || echo "$f:$rest"; done)
if [ -n "$treffer" ]; then echo "$treffer" | head -50; echo "Offen: $(echo "$treffer" | wc -l | tr -d ' ') Stellen"; exit 1; fi
echo "Design zentral: keine losen Standardwerte."
