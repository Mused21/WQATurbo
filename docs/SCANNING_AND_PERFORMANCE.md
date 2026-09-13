# Scanning, Caching and Performance

## 1. Why the Turbo scanner exists

The original WQAchievements reward path could repeatedly rescan large sets of enabled maps while Blizzard reward data was still being populated asynchronously.

The failure mode was roughly:

```text
scan every map
→ one quest has incomplete reward data
→ retry
→ rescan every map
→ another quest is still incomplete
→ retry
→ ...
```

On a large account this caused visible frame-time spikes.

WQA Turbo changes the unit of retry from **the whole world scan** to **the individual unresolved quest**.

## 2. Scanner responsibilities

`Scanning/RewardScanner.lua` is responsible for dynamic reward enrichment.

It does not replace the static achievement/collectible mapping system.

Its job is:

1. discover World Quests on enabled maps;
2. apply basic filtering;
3. request missing reward data when needed;
4. inspect ready rewards;
5. classify useful rewards through existing WQA helpers;
6. leave unresolved quests in pending state;
7. retry pending quests later;
8. publish newly useful data progressively.

## 3. Frame budget

The scanner intentionally limits synchronous work per frame.

Current design constants include approximately:

```text
FRAME_BUDGET_MS                 2.0 ms
RETRY_INTERVAL_SECONDS          0.50 s
REISSUE_PRELOAD_AFTER_SECONDS   5.0 s
MAX_PRELOAD_REISSUES            2
MAX_PENDING_AGE_SECONDS         30 s
```

Always verify the constants in `Scanning/RewardScanner.lua` before relying on exact values.

### Why a frame budget is preferable to a quest-count budget

A quest can be cheap or unexpectedly expensive depending on:

- Blizzard cache state;
- reward type;
- item info readiness;
- other addons;
- collection APIs.

A wall-clock frame budget protects UI responsiveness better than "N quests per frame."

## 4. Initial scan versus pending retry

### Initial scan

The scanner walks enabled maps incrementally.

For each discovered quest it may:

- evaluate static/special relevance already present;
- query reward readiness;
- inspect reward items/currencies/reputation;
- mark the quest pending if information is not ready.

### Pending retry

A pending entry belongs to the unresolved quest.

Typical pending causes:

- Blizzard has quest data but not reward data;
- an item hyperlink is not ready;
- transmog source/appearance information is not ready.

A retry does **not** rebuild every map.

## 5. Reward-data preload

For quests with missing reward data the scanner can call:

```lua
C_TaskQuest.RequestPreloadRewardData(questID)
```

The request can be reissued after a delay, but only within bounded limits.

Some quests are intentionally excluded through `SkipRewardDataPreloadQuests` because Blizzard returns misleading/inaccurate results for them.

### Maintenance note

The canonical skip list lives in `Scanning/RewardScanner.lua`.

Do not casually delete the list: the exclusions were added because specific quests produced pathological reward-preload behavior.

## 6. Background enrichment

The scanner does not wait for every quest to be fully resolved before WQA Turbo becomes usable.

Instead:

```text
ready static/early results
    ↓
publish

pending quest becomes ready later
    ↓
classify reward
    ↓
mark the scan batch dirty
    ↓
at the end of the initial pass or retry batch:
    TurboPublishEnrichment()
    ↓
TaskResolver
    ↓
refresh open popup / new-task state
```

Initial reward inspection marks its batch dirty for item, currency, profession
and reputation classification. An item-only retry marks the batch dirty when it
finishes. Publication is coalesced at batch boundaries, so an open persistent
popup gains the resolved reward-based quests without rebuilding once per quest.
The scanner also retains the refresh mode that created it: Settings-triggered
enrichment republishes in silent `settings` mode, while ordinary background
discovery uses `new` mode.

## 7. Readiness in `Runtime/TaskResolver.lua`

Reward scanning and task display have separate readiness concerns.

Even after relevance exists, WQA may still need:

- quest link;
- item link;
- achievement link;
- currency link;
- mission link/reward text.

`TaskResolver` prepares each task individually.

A task that is ready can be published even if another task needs a link retry.

The readiness retry is coalesced through a timer rather than spawning uncontrolled timers.

## 8. Collection cache

Mount and pet journal scans are relatively expensive when repeated.

`Tracking/CollectionCache.lua` builds collection indexes once per refresh and lets static
registration and Settings completion grouping reuse them. Settings queries use
constant-time spell-ID/creature-ID lookups instead of walking a whole journal
for every displayed mount or pet.

The conceptual flow is:

```text
refresh
→ snapshot collection journal
→ register expansion collectible mappings against snapshot
→ discard/rebuild on next refresh as appropriate
```

Mode eligibility now uses `TrackingPolicy.GetState` after the same known-entry
checks. This helper returns flags without allocating tables or querying journals.
The once-per-refresh snapshots and per-quest tracking gates are unchanged.
Scanner changes in Step 3 only replace reward/mode literals with equal constants.

This avoids:

```text
for each expansion:
    for each mapped pet/mount:
        rescan entire Blizzard collection journal

for each Settings row:
    rescan the corresponding collection journal
```

## 9. What is cached and what is not

### Cached for display

The Turbo display layer retains the current built result state so ordinary display actions can render it immediately.

This is why:

- `/wqat`
- normal minimap left-click
- `/wqat popup`

are intended to be cheap.

### Rebuilt on explicit refresh

An explicit refresh rebuilds `questList` and starts a new reward scan.

### Important current limitation: dynamic reward relevance is not stale-while-revalidate cached

Static achievement relevance tends to reappear immediately because it is known from addon data.

Reward-derived transmog and similar dynamic results can temporarily disappear during a refresh until Blizzard reward/item data is discovered again.

This was observed during 1.1.0 development and is a documented future optimization candidate.

A possible future architecture is a session-local stale-while-revalidate cache keyed by quest ID/reward item, but it is **not current behavior**.

See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md).

## 10. Settings refresh

Most meaningful settings changes call a debounced refresh scheduler.

Desired behavior:

- coalesce multiple quick changes into one rebuild;
- no chat spam;
- do not automatically open a closed popup;
- if the persistent popup is already open, update it when new results are ready.
- if combat defers the refresh, retain the silent Settings publication mode
  until `PLAYER_REGEN_ENABLED` resumes it.

Bulk operations should trigger **one** debounced refresh, not one refresh per item.

## 11. Performance diagnostics

The scanner records counters such as:

- maps scanned;
- quest visits;
- pending quests;
- reward-pending quests;
- item-pending quests;
- retry checks;
- preload reissues;
- enriched quests;
- reputation checks;
- reputation matches;
- publishes;
- timed-out entries;
- number of slices;
- total scanner CPU time;
- maximum slice time;
- initial/enrichment duration.

Use:

```text
/wqat scan
/wqat perf
/wqat cache
```

for runtime diagnosis.

## 12. Performance invariants

Never reintroduce:

- synchronous global reward rescans on every retry;
- broad rescan because one item link is missing;
- collection-journal walks for every mapped collectible;
- minimap hover that triggers a full scan;
- popup opening that implicitly rebuilds everything;
- unbounded retry loops.

## 13. Diagnosing a missing dynamic reward

Use this order:

```text
Is the WQ discovered on an enabled map?
    ↓
Is reward data ready?
    ↓
Does CheckReward classify the actual item/currency?
    ↓
Was AddRewardToQuest called?
    ↓
Is questList populated?
    ↓
Does final eligibility allow it?
    ↓
Is task/link readiness satisfied?
    ↓
Is it in activeTasks?
    ↓
Does display render it?
```

This separates scanner bugs from classification bugs and publication bugs.

## 14. Reward classification versus scanner ownership

Do not put item IDs and one-off category rules into `Scanning/RewardScanner.lua` unless discovery itself requires scanner-specific behavior.

Preferred ownership:

```text
RewardScanner
    = when/how to inspect

CheckReward / data tables
    = what a reward means
```

`CheckReward()` resolves the authoritative reward link and aggregates retry
state. Focused local classifiers handle containers, gear upgrades, equipment
caches, transmog, reputation items, recipes, known/custom items and legacy
Azerite/conduit behavior. Each classifier publishes through the canonical
reward merge path.

The classifier split does not change pending-quest state or frame budgets.
During in-game verification, the scanner's existing batch publication was
corrected to include initial item/currency/profession inspection and completed
item retries, so an already-open popup receives those resolved results. The
scanner retains silent Settings publication semantics across asynchronous work.
