#!/usr/bin/env bash
# Download every Hebrish Android release APK (tags android-v*, application ID
# app.hebrish.dictation) from Hebrish-ASR/Hebrish-App into fdroid/repo/.
# Releases before 0.2.0 shipped as com.danielrosehill.parlance and are skipped.
set -euo pipefail
SRC=${SRC_REPO:-Hebrish-ASR/Hebrish-App}
DEST=${1:-fdroid/repo}
mkdir -p "$DEST"
gh release list -R "$SRC" --limit 200 --json tagName,isDraft,isPrerelease \
  -q '.[] | select(.isDraft|not) | select(.isPrerelease|not) | .tagName' |
  grep '^android-v' | while read -r tag; do
    ver=${tag#android-v}
    if [ "$(printf '%s\n0.2.0\n' "$ver" | sort -V | head -1)" != "0.2.0" ]; then
      echo "skip $tag (pre-0.2.0 package ID)"; continue
    fi
    gh release download "$tag" -R "$SRC" -p 'Hebrish-v*.apk' -D "$DEST" --skip-existing
    echo "got $tag"
  done
