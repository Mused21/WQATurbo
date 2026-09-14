#!/usr/bin/env python3
"""
WQA Turbo project validator.

Purpose:
- catch repository/package mistakes that Lua syntax checking cannot;
- stay dependency-free so it runs locally and in GitHub Actions;
- validate stable project invariants without coupling CI to implementation
  details that 1.2.0 is intentionally going to refactor.

Usage:
    python tools/validate_project.py
    python tools/validate_project.py --package
    python tools/validate_project.py --package path/to/WQATurbo-x.y.z.zip
"""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "WQATurbo.toc"
PKGMETA = ROOT / ".pkgmeta"

ALLOWED_CRITERIA_TYPES = {
    "ACHIEVEMENT",
    "AREA_POI",
    "MISSION_TABLE",
    "QUEST_FLAG",
    "QUEST_PIN",
    "QUEST_SINGLE",
    "QUESTS",
    "SPECIAL",
}

ALLOWED_FACTIONS = {
    "Alliance",
    "Horde",
}

REQUIRED_PROJECT_FILES = (
    "WQATurbo.toc",
    ".pkgmeta",
    "Core.lua",
    "Constants.lua",
    "Tracking/TrackingPolicy.lua",
    "Tracking/ContainerCompletion.lua",
    "Tracking/Achievements.lua",
    "Tracking/CollectionCache.lua",
    "Data/Expansions/Legion.lua",
    "Data/RuntimeData.lua",
    "Data/ContainerCollectibles.lua",
    "Utilities.lua",
    "WQATurbo.lua",
    "Scanning/RewardScanner.lua",
    "Runtime/Runtime.lua",
    "Runtime/Display.lua",
    "Runtime/TaskResolver.lua",
    "Performance.lua",
    "UI/Tooltip.lua",
    "UI/Options/Shared.lua",
    "UI/Options/Custom.lua",
    "UI/Options/Tracking.lua",
    "UI/Options/Rewards.lua",
    "UI/Options.lua",
    "Rewards/Reward.lua",
    "Rewards/RewardType.lua",
    "Criterias/CriteriaType.lua",
    "Criterias/AreaPoi.lua",
    "tools/test_reward_classifier.lua",
    "tools/test_reward_scanner.lua",
    "tools/test_runtime_lifecycle.lua",
    "tools/test_task_resolver.lua",
    "tools/test_tooltip_lifecycle.lua",
    "tools/test_custom_options.lua",
    "tools/load_options.lua",
    "tools/test_options_structure.lua",
)

REQUIRED_PACKAGE_ITEMS = (
    "WQATurbo/WQATurbo.toc",
    "WQATurbo/Constants.lua",
    "WQATurbo/Tracking/TrackingPolicy.lua",
    "WQATurbo/Tracking/ContainerCompletion.lua",
    "WQATurbo/Data/RuntimeData.lua",
    "WQATurbo/Data/ContainerCollectibles.lua",
    "WQATurbo/Scanning/RewardScanner.lua",
    "WQATurbo/Runtime/Runtime.lua",
    "WQATurbo/UI/Options/Shared.lua",
    "WQATurbo/UI/Options/Custom.lua",
    "WQATurbo/UI/Options/Tracking.lua",
    "WQATurbo/UI/Options/Rewards.lua",
    "WQATurbo/UI/Options.lua",
)

REQUIRED_PACKAGE_PREFIXES = (
    "WQATurbo/Libs/AceAddon-3.0/",
    "WQATurbo/Libs/AceConfig-3.0/",
    "WQATurbo/Libs/AceDB-3.0/",
    "WQATurbo/Libs/LibDBIcon-1.0/",
    "WQATurbo/Libs/LibQTip-1.0/",
    "WQATurbo/Libs/LibStub/",
)

FORBIDDEN_PACKAGE_PREFIXES = (
    "WQATurbo/.git/",
    "WQATurbo/.github/",
    "WQATurbo/tools/",
    "WQATurbo/dist/",
    "WQATurbo/docs/",
)

FORBIDDEN_PACKAGE_ITEMS = (
    "WQATurbo/AGENTS.md",
    "WQATurbo/.travis.yml",
)

FORBIDDEN_REPOSITORY_SUFFIXES = (
    ".bak",
    ".orig",
    ".rej",
    ".tmp",
)

CRITERIA_RE = re.compile(r'\bcriteriaType\s*=\s*"([^"]+)"')
FACTION_RE = re.compile(r'\bfaction\s*=\s*"([^"]+)"')

CONSOLIDATED_RUNTIME_METHOD_OWNERS = {
    "AddMounts": "Tracking/CollectionCache.lua",
    "AddPets": "Tracking/CollectionCache.lua",
    "CheckWQ": "Runtime/TaskResolver.lua",
    "CreateQuestList": "WQATurbo.lua",
    "OnEnable": "Runtime/Runtime.lua",
    "Reward": "Scanning/RewardScanner.lua",
    "Show": "Runtime/Display.lua",
    "CreateCustomOptions": "UI/Options/Custom.lua",
    "CreateRewardOptions": "UI/Options/Rewards.lua",
    "PopulateRewardOptions": "UI/Options/Rewards.lua",
    "PopulateWorldQuestTypeOptions": "UI/Options/Rewards.lua",
    "PopulateTrackingOptions": "UI/Options/Tracking.lua",
    "ScheduleOptionsRefresh": "UI/Options.lua",
    "RefreshFromOptions": "UI/Options.lua",
}


class Validation:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def warn(self, message: str) -> None:
        self.warnings.append(message)

    def finish(self) -> int:
        for message in self.warnings:
            print(f"WARNING: {message}")

        if self.errors:
            for message in self.errors:
                print(f"ERROR: {message}", file=sys.stderr)
            print(
                f"\nValidation FAILED: {len(self.errors)} error(s), "
                f"{len(self.warnings)} warning(s).",
                file=sys.stderr,
            )
            return 1

        print(
            f"Validation PASSED: 0 errors, {len(self.warnings)} warning(s)."
        )
        return 0


def read_text(path: Path, validation: Validation) -> str:
    try:
        return path.read_text(encoding="utf-8-sig")
    except FileNotFoundError:
        validation.error(f"Missing file: {path.relative_to(ROOT)}")
    except UnicodeDecodeError as exc:
        validation.error(
            f"{path.relative_to(ROOT)} is not valid UTF-8: {exc}"
        )
    return ""


def validate_required_files(validation: Validation) -> None:
    for relative in REQUIRED_PROJECT_FILES:
        if not (ROOT / relative).is_file():
            validation.error(f"Required project file is missing: {relative}")


def parse_toc_sources(text: str) -> list[str]:
    sources: list[str] = []

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        normalized = line.replace("\\", "/")
        if normalized.lower().endswith((".lua", ".xml")):
            sources.append(normalized)

    return sources


def validate_toc(validation: Validation) -> None:
    text = read_text(TOC, validation)
    if not text:
        return

    if "## Version: @project-version@" not in text:
        validation.error(
            "WQATurbo.toc must keep '## Version: @project-version@'; "
            "release automation owns version substitution."
        )

    if "## SavedVariables: WQATurboDB" not in text:
        validation.error(
            "WQATurbo.toc must declare WQATurboDB as SavedVariables."
        )

    sources = parse_toc_sources(text)
    seen: set[str] = set()

    # Constants and tracking policy must exist before their runtime consumers.
    startup = ("Core.lua", "Constants.lua", "Tracking/TrackingPolicy.lua")
    for source in startup:
        if source not in sources:
            validation.error(f"TOC must load {source}.")
    if all(source in sources for source in startup):
        positions = [sources.index(source) for source in startup]
        if positions != sorted(positions):
            validation.error(
                "TOC must load Core, Constants, then "
                "Tracking/TrackingPolicy.lua."
            )
        for source in sources[:positions[-1]]:
            if source.endswith(".lua") and not source.startswith("Libs/") and source not in startup:
                validation.error(
                    "TOC must load Tracking/TrackingPolicy.lua before "
                    f"{source}."
                )

    runtime_data = "Data/RuntimeData.lua"
    runtime_consumers = ("Utilities.lua", "WQATurbo.lua", "UI/Options.lua")
    for source in (runtime_data, *runtime_consumers):
        if source not in sources:
            validation.error(f"TOC must load {source}.")
    if runtime_data in sources:
        data_position = sources.index(runtime_data)
        for consumer in runtime_consumers:
            if consumer in sources and data_position > sources.index(consumer):
                validation.error(
                    f"TOC must load {runtime_data} before {consumer}."
                )

    options_order = (
        "Performance.lua", "UI/Options/Shared.lua", "UI/Options/Custom.lua",
        "UI/Options/Tracking.lua", "UI/Options/Rewards.lua", "UI/Options.lua",
    )
    for source in options_order:
        if source not in sources:
            validation.error(f"TOC must load {source}.")
    if all(source in sources for source in options_order):
        positions = [sources.index(source) for source in options_order]
        if positions != sorted(positions):
            validation.error("TOC options modules are not in dependency order.")

    container_data = "Data/ContainerCollectibles.lua"
    container_owner = "Tracking/ContainerCompletion.lua"
    container_consumer = "WQATurbo.lua"
    for source in (container_data, container_owner, container_consumer):
        if source not in sources:
            validation.error(f"TOC must load {source}.")
    if all(source in sources for source in (container_data, container_owner, container_consumer)):
        positions = [sources.index(source) for source in (container_data, container_owner, container_consumer)]
        if positions != sorted(positions):
            validation.error(
                "TOC must load container collectible data, completion logic, "
                "then WQATurbo.lua."
            )

    for source in sources:
        key = source.lower()
        if key in seen:
            validation.error(f"Duplicate TOC source entry: {source}")
        seen.add(key)

        # Externals under Libs/ are populated by the packager and therefore may
        # legitimately be absent in a clean source checkout.
        if source.startswith("Libs/"):
            continue

        if not (ROOT / source).is_file():
            validation.error(f"TOC references a missing file: {source}")


def parse_pkgmeta_ignore(text: str) -> set[str]:
    """
    Parse the simple top-level ignore list used by this project.

    This intentionally is not a general YAML parser so CI remains
    dependency-free.
    """
    ignored: set[str] = set()
    in_ignore = False

    for raw_line in text.splitlines():
        if raw_line.strip() == "ignore:":
            in_ignore = True
            continue

        if not in_ignore:
            continue

        if raw_line and not raw_line[0].isspace():
            break

        match = re.match(r"^\s*-\s+(.+?)\s*$", raw_line)
        if match:
            ignored.add(match.group(1).strip().strip("'\""))

    return ignored


def validate_pkgmeta(validation: Validation) -> None:
    text = read_text(PKGMETA, validation)
    if not text:
        return

    ignored = parse_pkgmeta_ignore(text)
    required_ignored = {".git", ".github", "tools", "dist", "docs", "AGENTS.md"}

    for path in sorted(required_ignored - ignored):
        validation.error(
            f".pkgmeta ignore list must contain '{path}' so development "
            "files do not ship in release packages."
        )


def iter_project_files():
    excluded_dirs = {
        ".git",
        ".release",
        "Libs",
        "__pycache__",
    }

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue

        relative = path.relative_to(ROOT)
        if any(part in excluded_dirs for part in relative.parts):
            continue
        yield path, relative


def validate_repository_hygiene(validation: Validation) -> None:
    if (ROOT / ".travis.yml").exists():
        validation.error(
            "Obsolete .travis.yml must not be restored; GitHub Actions own CI."
        )

    for _, relative in iter_project_files():
        name = relative.name.lower()

        if name.endswith("~"):
            validation.error(f"Editor backup file is committed/present: {relative}")

        for suffix in FORBIDDEN_REPOSITORY_SUFFIXES:
            if name.endswith(suffix):
                validation.error(
                    f"Backup/reject/temp artifact should not be in the repository: "
                    f"{relative}"
                )


def validate_static_data(validation: Validation) -> None:
    data_dir = ROOT / "Data" / "Expansions"
    if not data_dir.is_dir():
        validation.error("Missing Data/Expansions directory.")
        return

    lua_files = sorted(data_dir.glob("*.lua"))
    if not lua_files:
        validation.error("No expansion data files found under Data/Expansions.")
        return

    for path in lua_files:
        text = read_text(path, validation)
        relative = path.relative_to(ROOT)

        for criteria_type in CRITERIA_RE.findall(text):
            if criteria_type not in ALLOWED_CRITERIA_TYPES:
                validation.error(
                    f"{relative}: unknown criteriaType '{criteria_type}'. "
                    f"Known values: {', '.join(sorted(ALLOWED_CRITERIA_TYPES))}"
                )

        for faction in FACTION_RE.findall(text):
            if faction not in ALLOWED_FACTIONS:
                validation.error(
                    f"{relative}: unsupported faction '{faction}'. "
                    "Expected Alliance or Horde."
                )


def validate_namespace_identity(validation: Validation) -> None:
    """Enum modules must preserve the namespaces initialized by Core.lua."""
    reward_type = read_text(ROOT / "Rewards" / "RewardType.lua", validation)
    criteria_type = read_text(ROOT / "Criterias" / "CriteriaType.lua", validation)

    if re.search(r"\bWQA\.Rewards\s*=\s*{", reward_type):
        validation.error(
            "Rewards/RewardType.lua replaces the whole WQA.Rewards namespace. "
            "Assign WQA.Rewards.RewardType instead."
        )

    if re.search(r"\bWQA\.Criterias\s*=\s*{", criteria_type):
        validation.error(
            "Criterias/CriteriaType.lua replaces the whole WQA.Criterias "
            "namespace. Assign WQA.Criterias.CriteriaType instead."
        )


def validate_runtime_method_owners(validation: Validation) -> None:
    """Consolidated runtime methods must have exactly one source owner."""
    toc_sources = parse_toc_sources(read_text(TOC, validation))

    for method, expected_owner in CONSOLIDATED_RUNTIME_METHOD_OWNERS.items():
        pattern = re.compile(
            rf"(?:\bfunction\s+(?:WQA|WQATurbo):{re.escape(method)}\s*\("
            rf"|\b(?:WQA|WQATurbo)\.{re.escape(method)}\s*=\s*function\s*\()"
        )
        owners: list[str] = []

        for source in toc_sources:
            if not source.endswith(".lua") or source.startswith("Libs/"):
                continue

            text = read_text(ROOT / source, validation)
            owners.extend(source for _ in pattern.finditer(text))

        if owners != [expected_owner]:
            validation.error(
                f"WQA:{method} must have one canonical owner in "
                f"{expected_owner}; found: {owners or 'none'}."
            )


def validate_qtip_lifecycle(validation: Validation) -> None:
    """All addon-owned LibQTip releases must use UI/Tooltip.lua's helper."""
    toc_sources = parse_toc_sources(read_text(TOC, validation))
    release_owners: list[str] = []
    detach_owners: list[str] = []

    for source in toc_sources:
        if not source.endswith(".lua") or source.startswith("Libs/"):
            continue

        text = read_text(ROOT / source, validation)
        release_owners.extend(
            source for _ in re.finditer(r"\bLibQTip:Release\s*\(", text)
        )
        detach_owners.extend(
            source
            for _ in re.finditer(r"\b(?:self|WQA)\.tooltip\s*=\s*nil", text)
        )

    if release_owners != ["UI/Tooltip.lua"]:
        validation.error(
            "LibQTip release must have one canonical owner in UI/Tooltip.lua; "
            f"found: {release_owners or 'none'}."
        )

    if detach_owners != ["UI/Tooltip.lua"]:
        validation.error(
            "WQA tooltip detachment must have one canonical owner in "
            f"UI/Tooltip.lua; found: {detach_owners or 'none'}."
        )


def find_release_zip() -> Path | None:
    release_dir = ROOT / ".release"
    candidates = [
        path
        for path in release_dir.glob("WQATurbo-*.zip")
        if "nolib" not in path.name.lower()
    ]
    if not candidates:
        return None
    return max(candidates, key=lambda path: path.stat().st_mtime)


def validate_package(path: Path, validation: Validation) -> None:
    if not path.is_file():
        validation.error(f"Package ZIP does not exist: {path}")
        return

    try:
        with zipfile.ZipFile(path) as archive:
            names = set(archive.namelist())
    except zipfile.BadZipFile as exc:
        validation.error(f"Invalid ZIP package {path}: {exc}")
        return

    for required in REQUIRED_PACKAGE_ITEMS:
        if required not in names:
            validation.error(f"Missing from package: {required}")

    for forbidden in FORBIDDEN_PACKAGE_ITEMS:
        if forbidden in names:
            validation.error(f"Development-only file leaked into package: {forbidden}")

    for prefix in REQUIRED_PACKAGE_PREFIXES:
        if not any(name.startswith(prefix) for name in names):
            validation.error(f"Missing required package content: {prefix}")

    for prefix in FORBIDDEN_PACKAGE_PREFIXES:
        offending = sorted(name for name in names if name.startswith(prefix))
        if offending:
            validation.error(
                f"Development-only content leaked into package under {prefix} "
                f"(example: {offending[0]})"
            )

    for name in sorted(names):
        lowered = name.lower()
        if lowered.endswith("~") or lowered.endswith(
            FORBIDDEN_REPOSITORY_SUFFIXES
        ):
            validation.error(f"Backup/temp artifact leaked into package: {name}")

    print(f"Validated package: {path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--package",
        nargs="?",
        const="AUTO",
        metavar="ZIP",
        help=(
            "also validate a packaged addon ZIP; omit ZIP to use the newest "
            ".release/WQATurbo-*.zip"
        ),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    validation = Validation()

    validate_required_files(validation)
    validate_toc(validation)
    validate_pkgmeta(validation)
    validate_repository_hygiene(validation)
    validate_static_data(validation)
    validate_namespace_identity(validation)
    validate_runtime_method_owners(validation)
    validate_qtip_lifecycle(validation)

    if args.package:
        package = (
            find_release_zip()
            if args.package == "AUTO"
            else Path(args.package).resolve()
        )
        if package is None:
            validation.error(
                "No packaged WQATurbo ZIP found under .release/."
            )
        else:
            validate_package(package, validation)

    return validation.finish()


if __name__ == "__main__":
    raise SystemExit(main())
