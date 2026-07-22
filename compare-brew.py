#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Compare installed Homebrew packages against what the Ansible playbook declares.

Run on the Mac:  ./compare-brew.py
"""
import re
import subprocess
import sys
from pathlib import Path

import yaml

VARS = Path(__file__).parent / "roles" / "divadvo_mac" / "vars" / "main.yml"


def render(value, scalars):
    """Resolve {{ var }} refs using the file's own top-level scalar vars."""
    return re.sub(
        r"\{\{\s*(\w+)\s*\}\}",
        lambda m: str(scalars.get(m.group(1), m.group(0))),
        value,
    )


def brew(*args):
    out = subprocess.run(["brew", "list", *args], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"brew list {' '.join(args)} failed:\n{out.stderr}")
    return set(out.stdout.split())


def report(title, declared, installed, footer=""):
    missing = sorted(declared - installed)
    extra = sorted(installed - declared)
    print(f"\n=== {title} ===")
    print(f"declared: {len(declared)}   installed: {len(installed)}")
    print(f"\nMissing (declared, not installed) [{len(missing)}]:")
    print("\n".join(f"  - {p}" for p in missing) or "  (none)")
    print(f"\nExtra (installed, not declared) [{len(extra)}]:")
    print("\n".join(f"  + {p}" for p in extra) or "  (none)")
    if footer:
        print(f"\n{footer}")


def main():
    data = yaml.safe_load(VARS.read_text())
    scalars = {k: v for k, v in data.items() if isinstance(v, (str, int))}

    formulae = {render(p, scalars) for p in data["homebrew_packages"]}
    casks = {render(p, scalars) for p in data["homebrew_cask_packages"]}

    report("FORMULAE", formulae, brew("--formula"),
           footer="Note: 'Extra' formulae include auto-installed dependencies (expected).")
    report("CASKS", casks, brew("--cask"))


if __name__ == "__main__":
    main()
