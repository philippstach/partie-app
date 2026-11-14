#!/bin/zsh
# Ein Branch in den Probe-Branch: merge, xcstrings-Konflikt automatisch, Build. Aufruf: Werkzeug/integrieren-schritt.sh <branch>
set -u
b=$1
git merge --no-edit "$b" 2>&1 | grep -E "CONFLICT|Merge made|Already|Fast-forward|error"
if git diff --name-only --diff-filter=U | grep -q .; then
  if git diff --name-only --diff-filter=U | grep -qv "Localizable.xcstrings"; then echo "KONFLIKT in Code:"; git diff --name-only --diff-filter=U; exit 2; fi
  python3 Werkzeug/xcstrings-merge.py App/Ressourcen/Localizable.xcstrings && git add App/Ressourcen/Localizable.xcstrings && git commit -qm "$b gemerged (xcstrings beidseitig behalten)"
fi
xcodebuild -project Partie.xcodeproj -scheme Partie -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD" | sort -u | head
