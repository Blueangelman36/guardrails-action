# Notes for coding agents

This repository is one file that matters (`action.yml`) and the CI that proves it
(`.github/workflows/ci.yml`, probes built by `tests/make-probe.sh`).

- Every probe that expects a failure must keep expecting one. A probe changed to
  pass is a guardrail switched off.
- The asof and chesterton pins are full commits with the release in a trailing
  comment. `asof.ini` reads that comment, so keep the `@<sha> # vX.Y.Z` shape.
- `continue-on-error` on the two check steps is deliberate: without it a failing
  asof would skip fence, and the second report would be missing from the run.
- `require: true` by default because an action that finds nothing to check and
  passes looks exactly like one that checked everything.
