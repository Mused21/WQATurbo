# Commands and Diagnostics

## User/developer slash commands

### `/wqat`

Show current cached results immediately.

This should not start a broad scan.

### `/wqat refresh`

Explicit rebuild/rescan.

Use when:

- testing new mappings;
- testing reward classification;
- forcing Blizzard reward data to be reconsidered.

### `/wqat new`

Refresh/new-task behavior used for newly discovered results.

### `/wqat popup`

Open persistent cached popup.

### `/wqat perf`

Show performance diagnostics.

Useful for:

- peak timings;
- call counts;
- total/average durations;
- regression testing.

### `/wqat scan`

Show reward scanner diagnostics.

Unreleased 1.3.0 also reports current readiness pending IDs and the last task
and emissary timeout snapshots through `/wqat scan` and `/wqat perf`.
Keys distinguish World Quests, missions (with pending item IDs when known),
mission lists (follower type), Quest Pin maps, POIs with map IDs, emissary
quests and bounty maps. `none` means no recorded entries for that category.
Timeout records reset on a full refresh and produce no automatic chat output.
A timeout stops retries; it does not prove the content is inactive.

Useful for:

- pending quest counts;
- preload requests/reissues;
- retry state;
- timing;
- reputation checks/matches;
- progressive publishes.

### `/wqat readiness`

Show only current pending IDs and the most recent task/emissary timeout
snapshots. This is the focused form of the readiness section also printed by
`/wqat scan` and `/wqat perf`.

### `/wqat cache`

Show collection-cache diagnostics.

### `/wqat reset`

Reset diagnostic counters.

### `/wqat import`

Import WQAchievements settings through migration flow.

### Legacy `/wqa`

Retained as a compatibility alias/path.

Do not remove casually because existing users/macros may still use it.

### Direct diagnostic aliases

`/wqaperf`, `/wqascan` and `/wqacache` remain available as direct aliases for
their corresponding diagnostic output.

## Diagnostic strategy by bug type

### Quest does not appear at all

Check:

```text
1. Is map supported/enabled?
2. Does Blizzard report the WQ active?
3. Is static/dynamic relevance added to questList?
4. Does final eligibility allow it?
5. Is task ready?
6. Is task in activeTasks?
```

Useful one-off Lua probes:

```lua
/run print(C_TaskQuest.IsActive(QUEST_ID))
```

```lua
/run print(GetNumQuestLogRewards(QUEST_ID))
```

```lua
/run for i=1,GetNumQuestLogRewards(QUEST_ID) do local n,_,_,_,_,id=GetQuestLogRewardInfo(i,QUEST_ID); print(i,id,n) end
```

Inspect WQA runtime state only during local debugging; avoid shipping diagnostic globals.

### Reward is visible in game but not classified

Check the authoritative reward item ID:

```lua
GetQuestLogRewardInfo(index, questID)
```

Then verify `CheckReward()` reaches the expected classification table/option.

### Static achievement appears despite disabled zone

Inspect final:

```lua
ShouldIncludeWorldQuestForCurrentMode()
```

The scanner's enabled map list is not enough.

### Transmog is missing

Check in order:

```text
item link ready?
IsTransmogable?
appearanceID/sourceID ready?
source ownership?
any appearance source ownership?
Unknown Appearance / Unknown Source settings?
```

Do not debug ATT collected state as if it were authoritative.

### Popup is missing results that `/wqat scan` says were matched

Inspect:

```text
questList
→ TaskResolver final eligibility
→ readiness
→ activeTasks
→ Display popup rebuild
```

Do not immediately patch discovery.

## Performance diagnosis

A normal scanner should spend work in small slices.

Warning signs:

- one call hundreds of milliseconds;
- every reward retry revisits all maps;
- settings bulk action triggers dozens/hundreds of refreshes;
- collection journal queried inside deep nested loops;
- popup hover triggers a scan.

## Git/static diagnostics

Always use:

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

## Lua syntax

CI uses Lua 5.1 syntax validation for addon Lua files outside `Libs`/release output.

Local equivalent if available:

```powershell
luac -p WQATurbo.lua
```

or Lua 5.1-specific binary where installed.

## Scanner debugging principle

Keep diagnostics observational.

Do not alter scanner scheduling just to make debugging output easier.

A diagnostic should answer:

```text
What phase?
How many maps/quests?
How many pending?
Why pending?
How many retry/reissues?
How much CPU?
What was published?
```
