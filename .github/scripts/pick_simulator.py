#!/usr/bin/env python3
"""Print "<udid> <name>" for the newest available iPhone simulator.

CI images differ in the simulators they ship, so the destination is resolved at
run time instead of being hard-coded in a workflow.
"""

import json
import subprocess
import sys


def available_devices() -> dict:
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)["devices"]


def main() -> int:
    candidates = []
    for runtime, devices in available_devices().items():
        if "iOS" not in runtime:
            continue
        version = tuple(int(part) for part in runtime.split("iOS-")[-1].split("-") if part.isdigit())
        if not version:
            continue
        for device in devices:
            if device["name"].startswith("iPhone") and device.get("isAvailable", True):
                candidates.append((version, device["name"], device["udid"]))

    if not candidates:
        print("No available iPhone simulator found", file=sys.stderr)
        return 1

    candidates.sort()
    _, name, udid = candidates[-1]
    print(f"{udid} {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
