#!/bin/zsh
# Merged alle angegebenen Branches nacheinander (xcstrings automatisch). Code-Konflikt: Abbruch mit Liste. Aufruf: Werkzeug/integrieren-alle.sh b1 b2 ...
for b in "$@"; do
  n=$(git rev-list --count HEAD..$b 2>/dev/null) || { echo "$b: gibt es nicht"; continue; }
  [ "$n" = 0 ] && { echo "$b: schon drin"; continue; }
  echo "== $b ($n neue Commits)"
  git merge --no-edit $b 2>&1 | grep -E "CONFLICT|error"
  codekonf=$(git diff --name-only --diff-filter=U | grep -v Localizable.xcstrings)
  if [ -n "$codekonf" ]; then echo "CODE-KONFLIKT:"; echo "$codekonf"; exit 2; fi
  if git diff --name-only --diff-filter=U | grep -q xcstrings; then
    python3 Werkzeug/xcstrings-merge.py App/Ressourcen/Localizable.xcstrings && git add App/Ressourcen/Localizable.xcstrings && git commit -qm "$b gemerged (xcstrings beidseitig behalten)"
  fi
done
git log --oneline -1
