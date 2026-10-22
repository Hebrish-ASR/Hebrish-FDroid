#!/usr/bin/env bash
# Download every release APK of the Hebrish apps into fdroid/repo/:
#  - Hebrish app (app.hebrish.dictation): Hebrish-ASR/Hebrish-App, tags android-v*. Releases
#    before 0.2.0 shipped as com.danielrosehill.parlance and are skipped.
#  - Hebrish Keyboard (app.hebrish.keyboard): Hebrish-ASR/Hebrish-Keyboard, tags v*-hebrish.*.
#  - Meorav (beta) (app.hebrish.meorav): Hebrish-ASR/Meorav-App, tags vX.Y.Z, asset Meorav-X.Y.Z.apk
#    (added 2026-10-22). "beta" is in the app label, not the release flag: prereleases are skipped.
# `scripts/fetch_apks.sh --tags` prints "<package> <versionName>" per release instead, for
# needs_rebuild.py.
set -euo pipefail
APP=${SRC_REPO:-Hebrish-ASR/Hebrish-App}
KBD=${KBD_REPO:-Hebrish-ASR/Hebrish-Keyboard}
TTS=${TTS_REPO:-Hebrish-ASR/Meorav-App}
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
releases "$TTS" | { grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' || true; } | while read -r tag; do
  if [ $MODE = tags ]; then echo "app.hebrish.meorav ${tag#v}"; continue; fi
  gh release download "$tag" -R "$TTS" -p 'Meorav-*.apk' -D "$DEST" --skip-existing
  echo "got meorav $tag"
done
