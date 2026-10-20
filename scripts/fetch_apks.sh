#!/usr/bin/env bash
# Download every release APK of both Hebrish apps into fdroid/repo/:
#  - Hebrish app (app.hebrish.dictation): Hebrish-ASR/Hebrish-App, tags android-v*. Releases
#    before 0.2.0 shipped as com.danielrosehill.parlance and are skipped.
#  - Hebrish Keyboard (app.hebrish.keyboard): Hebrish-ASR/Hebrish-Keyboard, tags v*-hebrish.*.
# `scripts/fetch_apks.sh --tags` prints "<package> <versionName>" per release instead, for
# needs_rebuild.py.
set -euo pipefail
APP=${SRC_REPO:-Hebrish-ASR/Hebrish-App}
KBD=${KBD_REPO:-Hebrish-ASR/Hebrish-Keyboard}
MODE=fetch; [ "${1:-}" = "--tags" ] && { MODE=tags; shift; }
DEST=${1:-fdroid/repo}

releases() { # repo
  gh release list -R "$1" --limit 200 --json tagName,isDraft,isPrerelease \
    -q '.[] | select(.isDraft|not) | select(.isPrerelease|not) | .tagName'
}

[ $MODE = fetch ] && mkdir -p "$DEST"
releases "$APP" | { grep '^android-v' || true; } | while read -r tag; do
  ver=${tag#android-v}
  if [ "$(printf '%s\n0.2.0\n' "$ver" | sort -V | head -1)" != "0.2.0" ]; then
    [ $MODE = fetch ] && echo "skip $tag (pre-0.2.0 package ID)"; continue
  fi
  if [ $MODE = tags ]; then echo "app.hebrish.dictation $ver"; continue; fi
  gh release download "$tag" -R "$APP" -p 'Hebrish-v*.apk' -D "$DEST" --skip-existing
  echo "got $tag"
done
releases "$KBD" | { grep -E '^v.+-hebrish\.[0-9]+$' || true; } | while read -r tag; do
  if [ $MODE = tags ]; then echo "app.hebrish.keyboard ${tag#v}"; continue; fi
  gh release download "$tag" -R "$KBD" -p 'HebrishKeyboard-v*.apk' -D "$DEST" --skip-existing
  echo "got keyboard $tag"
done
