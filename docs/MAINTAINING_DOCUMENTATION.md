# Maintaining the Documentation

The purpose of this documentation set is to remain useful across releases.

A large static architecture document that is not updated is worse than no documentation, because it creates false confidence.

## 1. Documentation is part of the definition of done

Any PR that changes one of the following must update docs in the same PR:

- architecture/module ownership;
- runtime lifecycle;
- scanner behavior;
- caching behavior;
- SavedVariables/data shapes;
- setting path or semantics;
- slash commands;
- user-visible behavior;
- release/CI workflow;
- project invariant;
- known limitation;
- significant expansion data model.

## 2. Change-to-document matrix

| Changed area | Required docs |
|---|---|
| `Scanning/RewardScanner.lua` | `ARCHITECTURE.md`, `SCANNING_AND_PERFORMANCE.md`, invariants if needed |
| `Runtime/TaskResolver.lua` | `ARCHITECTURE.md`, `SCANNING_AND_PERFORMANCE.md` |
| `Runtime/Display.lua` | `ARCHITECTURE.md`, `FUNCTIONAL_REFERENCE.md` |
| `Runtime/Runtime.lua` | `ARCHITECTURE.md`, `COMMANDS_AND_DIAGNOSTICS.md` |
| `Tracking/CollectionCache.lua` | `SCANNING_AND_PERFORMANCE.md`, `DATA_MODEL.md` |
| `UI/Tooltip.lua` | `FUNCTIONAL_REFERENCE.md`, invariants |
| `UI/Options.lua` | `SETTINGS_REFERENCE.md`, `FUNCTIONAL_REFERENCE.md` |
| `Migration.lua` | `ARCHITECTURE.md`, `FUNCTIONAL_REFERENCE.md` |
| `Rewards/*` | `DATA_MODEL.md`; functional docs if semantics changed |
| `Criterias/*` | `DATA_MODEL.md`, `DEVELOPMENT_GUIDE.md` |
| `Data/*` shape | `DATA_MODEL.md`, `DEVELOPMENT_GUIDE.md` |
| new user command | `COMMANDS_AND_DIAGNOSTICS.md`, `FUNCTIONAL_REFERENCE.md` |
| release workflow | `RELEASE_AND_CI.md`, invariants if relevant |
| new major/minor release | `VERSION_X.Y.Z.md` or update current version file |
| bug exposes new invariant | `INVARIANTS_AND_REGRESSION_GUARDS.md` |
| unresolved/proven limitation | `KNOWN_LIMITATIONS.md` |

## 3. PR documentation checklist

Copy this into meaningful PRs:

```markdown
### Documentation
- [ ] I checked whether this changes architecture/module ownership.
- [ ] I checked whether this changes a setting or user-visible behavior.
- [ ] I checked whether this changes SavedVariables/runtime data shape.
- [ ] I checked whether this changes scanner/cache/performance behavior.
- [ ] I checked whether this adds/removes a command or diagnostic.
- [ ] I checked whether this changes a project invariant.
- [ ] I updated the relevant file(s) under `docs/`, or the change truly requires no documentation update.
```

## 4. Keep docs code-oriented

Prefer:

```text
file name
function name
state table
data-flow diagram
invariant
test
```

over vague prose.

Good:

> `Runtime/TaskResolver.lua` owns final task readiness and publication.

Weak:

> The addon eventually checks quests.

## 5. Mark planned/research behavior clearly

Use explicit terms:

- **Current behavior**
- **Planned**
- **Research only**
- **Not shipped**
- **Known limitation**

Never describe an experiment as current architecture.

The Stitchyard research is a concrete example of why this matters.

## 6. Version baseline

At the top of `docs/README.md`, maintain:

```text
documentation baseline branch/release
last major documentation refresh date
```

After 1.1.0 releases, change:

```text
feature/popupandcontainers, planned 1.1.0
```

to:

```text
1.1.0 / master
```

## 7. Architecture-review routine

For a major/minor release, review these files even if they were not directly changed:

1. `WQATurbo.toc` — load order;
2. `Core.lua`;
3. `WQATurbo.lua`;
4. specialized modules;
5. `UI/Options.lua`;
6. new Data/expansion files;
7. workflows.

Then verify docs still describe actual runtime ownership.

## 8. Source search before documenting a function

Because of runtime overrides:

```powershell
git grep -n "function WQA:FUNCTION_NAME"
git grep -n "WQA.FUNCTION_NAME"
```

Do not document the first definition found.

## 9. Documentation review tests

A maintainer unfamiliar with a feature should be able to answer:

- Which file owns it?
- What state does it read/write?
- What makes it refresh?
- What is cached?
- What can be pending?
- What setting controls it?
- How do I test it?
- What invariant protects it?

If the docs cannot answer those, improve them.

## 10. Optional future CI improvement

A future low-risk CI enhancement could warn when core architectural files change without any `docs/` changes.

This should be advisory initially, because many small data fixes legitimately do not require architecture edits.

Do not introduce a brittle "every code PR must edit docs" hard failure without team/user agreement.
