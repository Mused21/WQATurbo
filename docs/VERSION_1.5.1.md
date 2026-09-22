# WQA Turbo 1.5.1

Status: **Ready for review**

Released baseline: **1.5.0**

Last reviewed: **2026-09-22**

## Scope

The 1.5.1 patch expands the opt-in Shadowlands Calling tracker from
the active covenant to any selected covenants. Blizzard's active-covenant
payload remains the live source for the daily rotation. A verified static table
maps each of the 24 daily objectives to its four covenant-specific quest IDs.
The same data identifies the four covenant sanctuaries so inactive variants do
not lose their localized zone group when Blizzard omits quest-zone metadata.

The feature adds four profile-scoped covenant selectors, an account-wide cache
of observed family expirations, and character-scoped completion locks with the
same expiration. Unknown future IDs remain limited to the active covenant.

## Release state

Implementation and automated verification are complete. The developer verified
the Settings layout, sanctuary grouping and combined Calling behavior in game
on 2026-09-22. The patch is ready for an unlabeled pull request so the normal
patch-release automation can determine the release level.
