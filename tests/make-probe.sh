#!/usr/bin/env bash
# Builds a small repository for one CI probe: make-probe.sh <probe> <dir>
#
#   clean             a true claim and a recorded reason whose code is still there
#   split             one number written two ways in two documents
#   removed-reason    a recorded reason whose code was deleted
#   nothing-to-check  no claims and no notes
#   nothing-allowed   the same, run with require: false
set -euo pipefail
probe=$1
cd "$2"

git init -q
git config user.name probe
git config user.email probe@example.invalid
printf 'guardrails-action/\n' > .gitignore

claims() {
  printf '[asof]\ninclude = README.md, docs.md\n' > asof.ini
  printf 'We support %s integrations. <!-- asof:integrations -->\n' "$1" > README.md
  printf 'The %s integrations are listed below. <!-- asof:integrations -->\n' "$2" > docs.md
}

reason() {
  python -m pip install --quiet "chesterton==0.1.1"
  printf 'import time\n\n\ndef fetch():\n    time.sleep(2)\n    return 1\n' > app.py
  git add -A && git commit -qm code
  fence add app.py:5 -m "the upstream API allows one request every two seconds"
}

case "$probe" in
  clean)
    claims 47 47
    reason
    ;;
  split)
    claims 47 52
    ;;
  removed-reason)
    reason
    sed -i '/sleep/d' app.py
    ;;
  nothing-to-check|nothing-allowed)
    printf '# A project\n' > README.md
    ;;
  *)
    echo "unknown probe: $probe" >&2
    exit 2
    ;;
esac

git add -A
git commit -qm probe
echo "probe '$probe' built:"
git ls-files
