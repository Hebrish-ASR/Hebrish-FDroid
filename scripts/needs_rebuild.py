#!/usr/bin/env python3
"""Exit 0 (rebuild) when the published index lacks a release; exit 1 when up to date.

Reads "<package> <versionName>" lines on stdin (from `scripts/fetch_apks.sh --tags`) and
compares them with the versions in https://fdroid.hebrish.app/repo/index-v2.json. A missing
or unreadable index, or a package not yet in it, means rebuild.
"""
import json
import sys
import urllib.request

INDEX = "https://fdroid.hebrish.app/repo/index-v2.json"

wanted = {tuple(line.split()) for line in sys.stdin if line.strip()}
try:
    with urllib.request.urlopen(INDEX, timeout=30) as r:
        pkgs = json.load(r)["packages"]
except Exception as e:  # first run, outage, or format change: rebuild
    print(f"index unreadable ({e}); rebuilding")
    sys.exit(0)
have = {
    (pkg, v["manifest"]["versionName"])
    for pkg, p in pkgs.items()
    for v in p["versions"].values()
}
missing = sorted(wanted - have)
print(f"published: {sorted(have)}; missing: {missing}")
sys.exit(0 if missing else 1)
