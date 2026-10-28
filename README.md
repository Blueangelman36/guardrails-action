# guardrails-action

*Two checks for the things tests never look at.*

Tests check what code does. They never notice:

- **a number in your docs that stopped being true**: the README still says 47
  integrations, the port changed in the config but not in the guide. Prose has no test
  suite, so these never fail. They just drift.
- **a line someone deleted because it looked pointless**: the `sleep(2)` that kept you
  under a rate limit, or the retry that papered over a vendor bug. The reason lived in
  someone's head, or in a closed PR.

This action runs the two tools built for exactly that, in one step:

| check | tool | fails when |
|---|---|---|
| numbers in docs | [asof](https://github.com/Blueangelman36/asof) 0.4.1 <!-- asof:asof-version --> | a number disagrees with the command that produces it, or with itself in another file |
| recorded reasons | fence, from [chesterton](https://github.com/Blueangelman36/chesterton) 0.1.1 <!-- asof:chesterton-version --> | code that has a recorded reason was removed or changed past recognition |

Each check runs only where it has something to check. Both run even when the first
fails, so you see both reports. And if neither finds anything to check, the step
fails, because a guardrail that guards nothing should not look green.

## Install it (easiest way)

You need a GitHub repository. Nothing to install on your computer.

1. In your repository on GitHub, click **Add file → Create new file**.
2. Name it `.github/workflows/guardrails.yml`.
3. Paste this, then click **Commit changes**:

   ```yaml
   name: guardrails
   on: [push, pull_request]
   jobs:
     guardrails:
       runs-on: ubuntu-latest
       permissions:
         contents: read
         pull-requests: write   # lets fence quote the reasons a PR touches
       steps:
         - uses: actions/checkout@v7
         - uses: Blueangelman36/guardrails-action@v1
           with:
             comment-on-pr: true
   ```

4. Open the **Actions** tab to watch it run.

The first run fails with "Neither check found anything to check". That is expected:
you have not given it anything to check yet. Do one of the two steps below, or both.

### Give asof something to check

Mark a number in a document with a comment naming it:

```markdown
We support 47 integrations. <!-- asof:integrations -->
```

Every place that states the same number gets the same name. Now if one says 47 and
another says 52, the build fails. To have asof work the number out for itself, add an
`asof.ini` with the command that produces it. The
[asof README](https://github.com/Blueangelman36/asof) has the details, and
`pip install asof-claims` then `asof suggest` lists the numbers in your docs worth
marking.

### Give fence something to check

On your computer, in the repository:

```bash
pip install chesterton
fence add src/client.py:42 -m "the vendor API allows one request every two seconds"
```

Commit the `.fence/` folder it creates. If someone later deletes that line, the build
fails and quotes the reason. `fence suggest` lists lines that probably have a reason
nobody wrote down.

## Settings

| input | default | what it does |
|---|---|---|
| `asof` | `auto` | `auto` runs when there is an `asof.ini` or an `asof:` marker in a tracked file. `true` or `false` to force it. |
| `asof-args` | `check` | Arguments for asof. `check --no-run --fail-on stale` for a scheduled job that checks only the dates. |
| `fence` | `auto` | `auto` runs when `.fence/notes` has notes. |
| `fence-implementation` | `python` | The build your notes were written with: `python` is what `pip install chesterton` gives you. Use `rust` if you wrote them with the Rust build (it reads JavaScript, TypeScript, Kotlin and Rust too). `fence doctor` says which. |
| `fence-args` | `check --strict` | `--strict` fails on a note the build could not read, instead of quietly skipping it. |
| `comment-on-pr` | `false` | Post the reasons a pull request touches as one comment on it, updated on every push. |
| `require` | `true` | Fail when neither check finds anything to check. Set `false` while adopting. |

Outputs `asof` and `fence` are each `passed`, `failed` or `skipped`, and the run's
summary page shows the same table.

## Pinning

`@v1` follows the latest 1.x release. To pin exactly, use a full commit:
`Blueangelman36/guardrails-action@<commit>`. Inside, asof and chesterton are pinned
by commit too. That matters for fence: each build of it writes its own anchor format,
and a project that once followed chesterton's main branch picked up a new format and
stayed green for a week while guarding nothing.

## How it is tested

The CI here builds a small repository for each case and runs the action against it,
the way your repository would:

| probe | expected |
|---|---|
| a true claim and a recorded reason still in place | passes |
| one number written two ways in two documents | fails |
| a recorded reason whose code was deleted | fails |
| nothing to check | fails |
| nothing to check, `require: false` | passes |

A probe that expects a failure and gets a pass fails the build. It also checks its
own README: the asof and chesterton releases named above are read from `action.yml`,
so when Dependabot moves a pin, CI fails until the README is updated to match.

## What is not verified

- The probes run on Linux only. Both tools support Windows and macOS runners, but this
  action has not been run on them.
- The `rust` fence implementation is passed through to chesterton's own action, which
  tests it. The probes here use `python`.

## Publishing a release

For the maintainer. On GitHub: **Releases → Draft a new release → Choose a tag**, type
`v1.0.0`, then **Publish release**. Then move the `v1` tag to the same commit, so
`@v1` users get it: **Releases → Draft a new release → Choose a tag**, type `v1`, set the
target to the same commit, and publish (or, from a terminal,
`git tag -f v1 v1.0.0 && git push -f origin v1`).

## License

MIT
