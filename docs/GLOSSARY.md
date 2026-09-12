# Glossary

**Active task**  
A relevant task that has passed current activity, eligibility and readiness checks and is included in `activeTasks`.

**Dynamic relevance**  
A reason to show a quest that depends on current Blizzard reward data, such as transmog, currency, gear or reputation.

**Enrichment**  
Background addition of dynamic relevance after the initial/static result set is already usable.

**Final eligibility gate**  
The publication check that enforces WQ type, War Mode, zone and activity state even if relevance was added earlier.

**Persistent popup**  
The scrollable/collapsible LibQTip World Quest list opened by `/wqat popup` or minimap left-click.

**Pending quest**  
A quest whose reward/item information is not ready. It is retried individually.

**Quest relevance**  
A reason stored in `questList` explaining why WQA cares about a quest.

**Reward classifier**  
Logic in shared reward handling (`CheckItems`/`CheckReward` and lookup tables) that translates raw Blizzard rewards into WQA reward types.

**Static relevance**  
A reason that can be determined from addon mappings and collection/completion state without current reward payloads.

**Specialized runtime module**

A focused module under `Scanning/`, `Runtime/`, or `Tracking/` that owns a
specific runtime responsibility formerly mixed into the compatibility core.

**Watched task**  
A task remembered as already seen for "new task" announcement behavior.

**WQ**  
World Quest.
