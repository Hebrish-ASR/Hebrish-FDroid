#!/usr/bin/env python3
"""Exit 0 (rebuild) when the published index lacks an Android release; exit 1 when up to date.

Compares the versionNames in https://fdroid.hebrish.app/repo/index-v2.json with the
android-v* release tags (0.2.0 and later) of Hebrish-ASR/Hebrish-Dictation, passed one
per line on stdin. A missing or unreadable index means rebuild.
"""
import json
import sys
import urllib.request

INDEX = "https://fdroid.hebrish.app/repo/index-v2.json"
PKG = "app.hebrish.dictation"

wanted = {line.strip().removeprefix("android-v") for line in sys.stdin if line.strip()}
try:
    with urllib.request.urlopen(INDEX, timeout=30) as r:
        idx = json.load(r)
    have = {v["manifest"]["versionName"] for v in idx["packages"][PKG]["versions"].values()}
except Exception as e:  # first run, outage, or format change: rebuild
    print(f"index unreadable ({e}); rebuilding")
    sys.exit(0)
missing = sorted(wanted - have)
print(f"published: {sorted(have)}; missing: {missing}")
sys.exit(0 if missing else 1)
