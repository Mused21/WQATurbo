# Release and CI

## 1. Version ownership

`WQATurbo.toc` contains:

```text
## Version: @project-version@
```

Do not manually replace this with a release number.

BigWigs/WowAce packaging and release automation own version substitution.

## 2. Pull-request validation

PRs into `master` run the validation workflow.

The validation pipeline includes:

1. checkout with full enough history for packaging/version context;
2. project structure, startup load order and hygiene validation;
3. Lua 5.1 syntax validation plus tracking-policy, reward-classifier,
   reward-scanner publication, runtime-lifecycle, task-resolver and
   tooltip-lifecycle regression checks;
4. BigWigs packager build with externals;
5. validation that required runtime modules and embedded libraries exist in the ZIP;
6. upload of PR test build artifact.

The artifact upload must include hidden files because the packager writes to `.release/`.

## 3. Packaging

`.pkgmeta` defines:

```text
package-as: WQATurbo
manual changelog: CHANGELOG.md
external libraries
ignored development files
```

Embedded libraries are pulled at package time.

No-lib packaging is disabled for the primary package.

## 4. Release semantics

Release workflow runs on merge/push to `master` (and supports manual dispatch).

PR label semantics:

```text
release:none   → do not release
release:minor  → increment minor
release:major  → increment major
no label       → patch release
```

Manual workflow dispatch can explicitly choose bump type.

## 5. 1.2.0

Because the latest stable tag is `v1.1.0` and `refactor/1.2.0` targets 1.2.0,
its release PR should use:

```text
release:minor
```

Do not manually tag 1.2.0 before the workflow.

## 6. Critical packaging/tag invariant

A historical workflow bug pushed the new tag before running the BigWigs packager.

The packager then saw HEAD as already/future-tagged and emitted behavior equivalent to:

```text
Found future tag ..., not packaging.
```

No `.release` package was produced.

Project invariant:

> **Package and validate the release artifact before pushing the new remote tag.**

Whenever `release.yml` is edited, explicitly verify that this remains true.

Do not casually reorder tag/package steps.

## 7. GitHub release

Release automation creates/updates an annotated semantic-version tag and attaches the packaged ZIP to a GitHub Release.

Generated release notes can be used, while `CHANGELOG.md` remains the package changelog source.

## 8. CurseForge

Current release integration uses a CurseForge package endpoint triggered by the GitHub release workflow.

Important project policy:

- GitHub → CurseForge legacy webhook remains disabled;
- release workflow uses the configured CurseForge package URL secret;
- CurseForge automatic packaging must remain enabled for that endpoint;
- avoid enabling duplicate delivery paths.

## 9. Pre-PR checklist

```powershell
git diff --check
git diff
git status
```

Verify:

- no accidental TOC version edit;
- no generated package files committed;
- no vendored library modifications;
- changelog updated;
- documentation updated;
- new settings have ON/OFF test;
- reward mappings tested in game where possible.

## 10. PR checklist for architectural changes

In addition:

- scanner/perf diagnostics tested;
- no broad synchronous rescan added;
- popup tooltip race safety retained;
- migration compatibility considered;
- data model docs updated;
- settings docs updated;
- invariants doc updated if a new invariant was introduced.

## 11. Release checklist

After PR validation and in-game testing:

1. merge into `master`;
2. release workflow determines version;
3. build/package;
4. validate package;
5. create/push tag according to safe workflow order;
6. create GitHub release;
7. trigger CurseForge;
8. verify public package contains embedded libs;
9. verify version displayed correctly in-game/project page;
10. check user reports before beginning risky follow-up work.

## 12. Credits/licenses

Preserve:

- WQAchievements/Urtgard credit;
- original contributors;
- embedded library licenses.

Do not remove attribution during rebranding/refactors.
