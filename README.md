# Hebrish F-Droid repository

The F-Droid repository for the Hebrish Android apps: the Hebrish app (`app.hebrish.dictation`),
Hebrish Keyboard (`app.hebrish.keyboard`, added 2026-10-20) and Meorav (beta)
(`app.hebrish.meorav`, experimental on-device TTS, added 2026-10-22). Add it to the
F-Droid client (or Neo Store, Droid-ify) and Hebrish installs and updates like any other app.

| | |
| --- | --- |
| Repository URL | `https://fdroid.hebrish.app/repo` |
| Signing key fingerprint (SHA-256) | `EF8C2D63D994A10CD489A978585510B47E47452EC09248591CB2C0F39C2BC1FA` |
| One-tap add link | <https://fdroid.hebrish.app/repo?fingerprint=EF8C2D63D994A10CD489A978585510B47E47452EC09248591CB2C0F39C2BC1FA> |
| Instructions for users | <https://hebrish.app/download#fdroid> |

This is a binary repository: the APKs are the ones built and signed by the release workflows of
[Hebrish-ASR/Hebrish-App](https://github.com/Hebrish-ASR/Hebrish-App) (tags `android-v*`) and
[Hebrish-ASR/Hebrish-Keyboard](https://github.com/Hebrish-ASR/Hebrish-Keyboard) (tags
`v*-hebrish.*`) and [Hebrish-ASR/Meorav-App](https://github.com/Hebrish-ASR/Meorav-App) (tags
`vX.Y.Z`), not rebuilt from source by F-Droid. All apps use the same signing key. The APK signing certificate is
`5CF6822350D0B2FF124021A0DF10BEC1C63A6E5E6159FA6029507134A1446994` (the same key as the
GitHub and CDN downloads, so an app installed from either updates from here). The repo signing
key above is a separate key that signs only the index.

## How it publishes

`.github/workflows/publish.yml` runs on push to `main`, on manual dispatch, on a
`repository_dispatch` of type `android-release`, and every hour. The scheduled run first
checks the live `index-v2.json` (`scripts/needs_rebuild.py`) and does nothing unless an
Android release is missing from it. A rebuild:

1. downloads every non-draft, non-prerelease release APK of the apps
   (`scripts/fetch_apks.sh`): Hebrish app `android-v*` at 0.2.0 or later (0.1.x shipped as
   `com.danielrosehill.parlance` and is skipped), Hebrish Keyboard `v*-hebrish.*`, Meorav
   `vX.Y.Z` (`Meorav-X.Y.Z.apk`; the app is "beta" by its label, so its releases must not be
   marked prerelease or they are skipped).
   `scripts/fetch_apks.sh --tags` lists `<package> <versionName>` pairs for
   `scripts/needs_rebuild.py`, which compares them with the live index,
2. runs `fdroid update` (fdroidserver 2.4.5) with the keystore written from secrets,
3. deploys `fdroid/repo/` to GitHub Pages as `/repo`, with a root page that redirects to the
   instructions on hebrish.app.

Nothing generated is committed: `fdroid/repo/` is rebuilt each time. `fdroid/tmp/` is kept in
the Actions cache so each APK's "added" date stays stable; if the cache is evicted the dates
reset to the rebuild date (cosmetic only).

A new release therefore appears within an hour. To publish at once: **Actions → Publish F-Droid
repo → Run workflow**, or `gh workflow run publish.yml -R Hebrish-ASR/Hebrish-FDroid`.

## Inputs

| File | What |
| --- | --- |
| `fdroid/config.yml` | Repo name, URL, description, key alias. Passwords come from `FDROID_KEY_PASSWORD` |
| `fdroid/metadata/app.hebrish.dictation.yml` | Store listing: name, summary, description, links, licence. Keep claims in line with hebrish.app (README there lists the sources) |
| `fdroid/metadata/app.hebrish.keyboard.yml` | Hebrish Keyboard store listing (GPL-3.0, HeliBoard credit) |
| `fdroid/metadata/app.hebrish.meorav.yml` | Meorav (beta) store listing (MIT app, non-commercial voice model, ~1.4 GB download). Icon in `app.hebrish.meorav/en-US/icon.png` (same as `Meorav-App/docs/icon-512.png`) |
| `fdroid/metadata/app.hebrish.dictation/en-US/icon.png` | App icon (the brand mark; the APK's own icon is adaptive XML, which fdroid cannot extract) |
| `fdroid/icon.png` | Repo icon. `repo_icon` is resolved from the cwd (`fdroid/`), not from `repo/icons/`: a file placed in `repo/icons/` is overwritten with a placeholder (fdroidserver 2.4.5, `index.py`, verified 2026-10-20) |

## Signing key

Created 2026-10-20: PKCS12, RSA 4096, alias `hebrish`, DN `CN=Hebrish, OU=F-Droid, O=Hebrish,
C=IL`, valid 30 years. Not in this repo. Copies:

- GitHub Actions secrets on this repo: `FDROID_KEYSTORE_B64` (base64 of the `.p12`) and
  `FDROID_KEY_PASSWORD` (store and key password are the same).
- 1Password, vault Development, item "Hebrish F-Droid repo signing key" (keystore attached as `keystore`, password field).
- On the maintainer's laptop: `~/.android/keystores/hebrish-fdroid-repo.p12`, password in the
  `.txt` next to it.

**Never replace this key.** Every user who added the repo pinned its fingerprint; a new key
makes their client reject the index, and they would have to remove and re-add the repo.

## Hosting

GitHub Pages (build type: workflow) with custom domain `fdroid.hebrish.app`: a Cloudflare DNS
`CNAME fdroid → hebrish-asr.github.io`, DNS only (not proxied), so GitHub can issue the
certificate.

## Building locally

```bash
cd fdroid
cp ~/.android/keystores/hebrish-fdroid-repo.p12 keystore.p12
export ANDROID_HOME=~/Development/Android/Sdk FDROID_KEY_PASSWORD=$(cat ~/.android/keystores/hebrish-fdroid-repo.txt)
../scripts/fetch_apks.sh repo
fdroid update
```
