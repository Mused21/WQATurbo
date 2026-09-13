# Documentation manifest

Baseline:
- Branch: `refactor/1.2.0`
- Target release: `1.2.0`
- Previous release baseline: `1.1.0`
- Generated/refreshed: `2026-09-13`

Current 1.2.0 work included:
- shared constants, tracking policy and runtime metadata ownership;
- collection-cache reuse in Settings;
- focused reward classifiers and progressive popup enrichment;
- centralized tooltip lifecycle;
- module organization and single-owner runtime entry points;
- shared Hide Exalted/maximum Renown control on World Quest and Mission Table
  reputation pages;
- pre-release correctness fixes for nested achievement forcing, quest-pin
  criteria, dual-slot StatWeightScore comparisons and Settings navigation.

Explicitly excluded from current architecture:
- experimental Abomination Stitchyard tracking (research only, reverted).
