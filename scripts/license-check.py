#!/usr/bin/env python3
"""Check dependency license compliance from a CycloneDX SBOM.

Parses a CycloneDX ``bom.json``'s ``components`` array and, for each component,
resolves its license using the same lookup CycloneDX itself uses:

  1. ``licenses[].expression``    an SPDX license expression, e.g. "(MIT OR Apache-2.0)"
  2. ``licenses[].license.id``    a clean SPDX license id, e.g. "Apache-2.0"
  3. ``licenses[].license.name``  free text, used when a license has no SPDX id

Two independent modes, meant to be run as two separate CI steps:

  --report              print a table of component/version/resolved-license.
                         Always exits 0 -- this is a report, not a gate.
  --enforce <allowlist>  compare every component's resolved license against an
                         allow-list file (one identifier per line, '#' comments
                         and blank lines ignored). Exits 1 if any component's
                         license is missing or not in the allow-list.

Stdlib only (json, argparse, sys) -- this has to run in a bare actions/setup-java
container with no extra pip installs.
"""
import argparse
import json
import sys

# A handful of real, legitimate licenses were never assigned a clean SPDX id --
# that's a known gap in the SPDX license list for these licenses, not a mistake
# in the dependency's metadata. CycloneDX represents them as free-text
# `license.name` values instead of `license.id`. We still resolve them to that
# literal name (same as any other free-text name) and compare the literal name
# against the allow-list; this set exists purely so the gap is documented in one
# place, and the license report can flag it, rather than looking like an error.
# The comment on each entry records the SPDX id it is functionally equivalent to.
SPECIAL_LICENSES = {
    "Bouncy Castle Licence": "MIT",
    "Eclipse Distribution License - Version 1.0": "BSD-3-Clause",
}

UNSPECIFIED = "UNSPECIFIED"


def resolve_license(component):
    """Return the list of candidate license identifier strings for one SBOM
    component, in the order they appeared, de-duplicated. Returns an empty list
    if the component has no usable license entry."""
    licenses = component.get("licenses") or []
    candidates = []
    for entry in licenses:
        if not isinstance(entry, dict):
            continue
        if "expression" in entry and entry["expression"]:
            candidates.append(entry["expression"])
            continue
        license_obj = entry.get("license") or {}
        if license_obj.get("id"):
            candidates.append(license_obj["id"])
        elif license_obj.get("name"):
            candidates.append(license_obj["name"])
        # An entry with none of expression/license.id/license.name is malformed
        # per the CycloneDX schema; skip it rather than crash the whole report.

    deduped = []
    for candidate in candidates:
        if candidate not in deduped:
            deduped.append(candidate)
    return deduped


def display_license(resolved):
    """Human-readable rendering of a resolve_license() result for the report table."""
    if not resolved:
        return UNSPECIFIED
    text = " OR ".join(resolved)
    notes = [f"{r} ~= {SPECIAL_LICENSES[r]}" for r in resolved if r in SPECIAL_LICENSES]
    if notes:
        text += "  [no SPDX id: " + "; ".join(notes) + "]"
    return text


def format_table(rows):
    headers = ("Component", "Version", "License")
    all_rows = [headers] + rows
    widths = [max(len(str(row[i])) for row in all_rows) for i in range(3)]

    def fmt_row(row):
        return "  ".join(str(cell).ljust(widths[i]) for i, cell in enumerate(row))

    lines = [fmt_row(headers), "  ".join("-" * w for w in widths)]
    lines.extend(fmt_row(row) for row in rows)
    return "\n".join(lines)


def run_report(components):
    rows = []
    for component in components:
        name = component.get("name", "<unknown>")
        version = component.get("version", "<unknown>")
        rows.append((name, version, display_license(resolve_license(component))))
    print(format_table(rows))
    return 0


def run_enforce(components, allowed):
    failures = []
    for component in components:
        name = component.get("name", "<unknown>")
        version = component.get("version", "<unknown>")
        resolved = resolve_license(component)
        if not resolved:
            failures.append(f"{name} {version}: no license specified in SBOM")
            continue
        if not any(candidate in allowed for candidate in resolved):
            failures.append(f"{name} {version}: license '{' OR '.join(resolved)}' is not in the allow-list")

    if failures:
        print(f"License compliance FAILED ({len(failures)} component(s)):", file=sys.stderr)
        for failure in failures:
            print(f"  ERROR: {failure}", file=sys.stderr)
        return 1

    print(f"License compliance OK: all {len(components)} component(s) have an allowed license.")
    return 0


def load_allowlist(path):
    allowed = set()
    with open(path, "r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            allowed.add(line)
    return allowed


def main():
    parser = argparse.ArgumentParser(description="Check CycloneDX SBOM component licenses.")
    parser.add_argument("--sbom", required=True, help="Path to a CycloneDX bom.json")
    parser.add_argument("--report", action="store_true", help="Print a license report table (always exits 0)")
    parser.add_argument(
        "--enforce",
        metavar="ALLOWLIST_FILE",
        help="Enforce components' licenses against an allow-list file (exits 1 on any violation)",
    )
    args = parser.parse_args()

    if not args.report and not args.enforce:
        parser.error("specify at least one of --report or --enforce")

    with open(args.sbom, "r", encoding="utf-8") as handle:
        sbom = json.load(handle)
    components = sbom.get("components", [])

    exit_code = 0
    if args.report:
        run_report(components)
    if args.enforce:
        allowed = load_allowlist(args.enforce)
        exit_code = run_enforce(components, allowed)

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
