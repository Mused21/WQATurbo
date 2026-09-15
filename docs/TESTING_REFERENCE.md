# Testing Reference

## 1. Philosophy

WQA Turbo has two kinds of correctness requirements:

1. **functional correctness** — the right tasks/rewards appear;
2. **performance correctness** — they appear without reintroducing synchronous broad scanning or UI stalls.

A feature is not finished until both are considered.

## Local regression checks

From the repository root with a Lua 5.1 interpreter:

```text
lua5.1 tools/test_tracking_policy.lua
lua5.1 tools/test_reward_classifier.lua
lua5.1 tools/test_reward_scanner.lua
lua5.1 tools/test_runtime_lifecycle.lua
lua5.1 tools/test_task_resolver.lua
lua5.1 tools/test_tooltip_lifecycle.lua
lua5.1 tools/test_custom_options.lua
lua5.1 tools/test_database_schema.lua
lua5.1 tools/test_options_structure.lua
```

The options structure suite builds representative expansion, tracking, reward
and custom pages using TOC load order, then checks search, settings scope and
shared refresh coalescing. An optional path to a pre-split `Options.lua` compares
generated metadata (function types, not callback identity), excluding generated
order numbers and intentional Gear-setting additions/removals.

In the local Windows workspace, Lua 5.1.5 is installed at:

```powershell
$lua = Join-Path $env:LOCALAPPDATA 'Programs/Lua/5.1.5/lua5.1.exe'
& $lua tools/test_tracking_policy.lua
```

The test loads actual registration and Settings methods with stubbed Blizzard
APIs. It covers default/disabled/always/exclusive/character-only modes, missing
owners, unknown values, owned/unowned collections, completed tracking quests,
unknown journal entries, achievement completion, nested character-only forcing,
missing quest-pin criterion IDs, exclusive owner cleanup, bulk state and one
refresh per bulk operation. It also checks that repeated registration and
Settings completion queries reuse journal snapshots, and that
`CreateQuestList()` invalidates both snapshots exactly once without a load-order
wrapper. Pet cases also cover inconsistent row ownership: species counts of
1/3 and 3/3 both count as owned and suppress Default tracking.

The reward-classifier test covers authoritative item-link fallback, missing
data retries, containers, gear upgrades, StatWeightScore dual-slot selection,
equipment caches, transmog and retry, reputation items, recipes, known/custom
items, Azerite traits and conduits. It can run the same cases against an
optional prior `WQATurbo.lua` path.

The reward-scanner test checks that initial reward inspection and completed
item retries dirty a publication batch, and that repeated flushes without new
work do not rebuild the display again. It also verifies that a scanner started
by a Settings refresh republishes silently while ordinary scans use new-task
mode. Its display checks cover refresh-mode visibility, first-access fallback
and cache-only popup routing through the canonical `Show()` owner, and it
asserts that `Scanning/RewardScanner.lua` supplies `Reward()`.

The runtime-lifecycle test exercises the canonical `OnEnable()` owner. It
checks Settings registration, startup-delay capping, recurring refreshes,
numeric Blizzard Settings category-ID capture, combat recovery, quest
completion, War Mode refresh and mission updates. It also invokes all three
AceDB profile callbacks through the real Options/Display refresh path, checking
queued refresh cancellation, silent immediate rebuild, watched-state reset and
LibDBIcon rebinding even with combat deferral enabled.

The task-resolver test exercises the canonical `CheckWQ()` owner. It checks
per-task readiness, retry coalescing/cancellation, final filtering and
Settings/popup/LDB publication modes.

The tooltip-lifecycle test checks exact-object ownership, stale `OnHide`
callbacks, idempotent release, attached-task cleanup and popup/LDB rebuild
ordering against the actual lifecycle helpers. POI hover tests remove metadata
after row creation and then restore it, checking fallback and recovery.

The reward/core suite additionally exercises real Quest Pin lookup with the
TaskResolver: nil and empty map results, independent ready-map publication,
per-pass lookup count, throttled requests, retry expiry and silent Settings
publication. Map-name tests verify fallback values are not cached permanently.
Task, POI, mission/item and emissary timeout diagnostics retain identifiable IDs.

The custom-editor test checks rejected IDs and duplicate adds, numeric map
storage, required Quest Pin maps, optional mission rewards, deletion cleanup,
and silent refresh coalescing through the actual Settings callbacks and timer.
Building the editor alone must not schedule a refresh.

The database-schema test covers a fresh database, representative legacy custom
tables, malformed containers, duplicate legacy/canonical IDs, idempotent repeat
application and protection from downgrading a future schema.

The runtime lifecycle test also guards against eagerly loading
`Blizzard_GarrisonUI` at startup while preserving mission-list update
scheduling through the `C_Garrison` scan path.

This is separate from `luac5.1 -p`, which checks syntax without running code.
All checks run in GitHub Actions; in-game smoke testing is still required.

## 2. Baseline smoke test

After any meaningful change:

```text
/reload
/wqat
/wqat popup
/wqat refresh
/wqat scan
/wqat perf
```

Also test:

- minimap hover;
- left-click;
- right-click;
- Shift+Left-click;
- popup close/reopen;
- collapse/expand;
- scrolling.

## 3. Static achievement test

Pick:

- one incomplete mapped achievement WQ;
- one completed criterion;
- one disabled zone.

Verify:

- incomplete active quest appears;
- completed criterion behaves according to tracking mode;
- disabled zone suppresses it even though static mapping exists.

## 4. Collection test

For mount/pet/toy mapping:

```text
unowned + Default     → show
owned + Default       → hide
owned + Always        → show
Don't track           → hide
exclusive mismatch    → hide
```

Verify collection cache diagnostics do not show repeated full journal walks.

## 5. Transmog matrix

Use a reward where appearance is collected but exact source is missing.

Expected:

| Unknown appearance | Unknown source | Show |
|---|---|---|
| On | On | Yes |
| On | Off | No |
| Off | On | Yes |
| Off | Off | No |

Also test an entirely unknown appearance.

External addon permutations:

- ATT only;
- CanIMogIt only;
- both;
- neither.

The relevance decision must remain the same.

## 6. Reputation test

For a directly rewarding WQ:

- faction enabled + not maxed → show;
- faction disabled → no rep reason;
- hide-maxed off + maxed → can match;
- hide-maxed on + maxed → do not match.

Include at least one friendship reputation when changing max-state logic.

## 7. Recipe test

Use a profession WQ whose tooltip contains a crafted-output hyperlink.

Verify WQA reports the actual recipe reward item, not the crafted result.

## 8. Settings debounce test

Rapidly change several entries or use bulk toggle.

Expected:

- one coalesced refresh;
- no repeated chat spam;
- popup only updates automatically if already open.

## 9. Popup lifecycle test

Repeatedly:

```text
open
collapse expansion
expand
close
open
refresh while open
move popup if position persistence enabled
```

Expected:

- no stale LibQTip errors;
- no nil tooltip callback;
- no duplicate popup;
- no stuck old rows;
- delayed old tooltip callbacks do not close or release the current popup.

## 10. Zone/type/War Mode test

Verify each final gate independently.

Especially test a statically relevant achievement quest to ensure scanner bypass is impossible.

## 11. 1.1.0 Shift+Left-click test

With popup closed:

```text
Shift+Left-click
```

Expected:

1. cached popup appears immediately;
2. silent refresh begins;
3. no chat spam;
4. popup updates when new dynamic results arrive.

With popup already open:

- no duplicate popup;
- refresh still occurs.

## 12. 1.1.0 Azerite Armor Cache

Precondition:

```text
Rewards > Gear > Azerite Armor Cache = enabled
Rewards > Gear > Azerite Armor Cache on this character = enabled
```

Use active BfA WQ rewarding item 163857.

Expected:

- appears even when obsolete item level cannot upgrade current gear.
- appears when one appearance for the active armor type is missing;
- disappears when the ordinary cache's active-armor pool is complete;
- stays hidden when only another armor type has a missing appearance;
- stays visible while Blizzard appearance data is unavailable;
- Dungeon and Warfront item-context links stay visible because their pools
  differ from the ordinary 73-source zone pool.

Disable option:

- disappears unless another reason matches.

Leave the profile-wide option enabled and disable only the per-character option:

- the cache disappears on that character;
- it remains enabled on another character using the same profile.

## 13. 1.1.0 generic cache semantics

For recognized Armor/Weapon cache:

- option enabled → cache itself makes WQ relevant;
- upgrade metadata can still appear;
- option disabled → no cache-category relevance.

For Zandalari Empire Equipment Cache, verify it remains visible with a missing
shared/current-armor appearance and disappears when that finite pool is
complete. Tortollan Trader's Stock must not match a cache category.

## 14. 1.1.0 Benthic tokens

With Armor Cache enabled, test an active Nazjatar WQ rewarding one of IDs 169477–169485.

Expected:

- token appears while an appearance for the active character's armor type is
  uncollected;
- token disappears when that armor-type pool is complete, even if another
  armor type is missing;
- a missing/uncached transmog source keeps the token visible and is retried;
- no requirement that it upgrade current gear.

## 15. 1.1.0 Dragonflight racing purses

With Racing reward containers enabled:

- active racing WQ with at least one uncollected manuscript from that purse → show;
- active racing WQ whose purse-specific manuscript pool is complete → hide;
- completing Reach Racer's four manuscripts must not hide any other purse.

Disable:

- disappear unless another reason matches.

IDs:

```text
199192
204359
205226
210549
```

## 16. Scanner performance regression test

After explicit refresh:

```text
/wqat scan
/wqat perf
```

Look for:

- bounded slice max;
- pending/retry per quest;
- no repeated global map scan due to one missing item;
- reasonable publish counts.

## 17. Fresh-login versus warm-cache testing

Blizzard APIs behave differently after a fresh login/reload than after data has already been viewed.

For dynamic reward changes test both:

1. fresh `/reload`, do not open relevant map manually;
2. warm state after map/item data has loaded.

Do not validate only against a warm cache.

## 18. Migration regression

When migration code changes:

- install original WQAchievements SavedVariables fixture;
- WQA Turbo DB absent;
- import path;
- old addon disabled;
- old addon temporarily enabled if required;
- reload;
- verify profile/options/custom data;
- verify namespace collision fixes;
- verify old addon is not left unintentionally active.

## 19. Release validation

Before PR:

```powershell
git diff --check
git diff
git status
```

Before commit:

```powershell
git diff --cached --check
git diff --cached
```

PR CI must:

- parse all addon Lua with Lua 5.1;
- package with externals;
- validate required libraries in ZIP;
- upload artifact.

## 20. Bug reproduction template

Record:

```text
Game version:
Addon branch/commit:
Other relevant addons:
Character/faction:
Zone/map:
Quest ID:
Reward item/currency ID:
Settings path/value:
Fresh reload or warm cache:
Expected:
Actual:
Commands/API probes:
Scanner diagnostics:
```

This makes future bug analysis far faster than screenshots alone.
