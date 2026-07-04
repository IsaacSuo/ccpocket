#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OVERRIDES="pubspec_overrides.yaml"
NOGMS_OVERRIDES="pubspec_overrides.nogms.yaml"
LOCKFILE="pubspec.lock"
BACKUP=""
LOCK_BACKUP=""

cleanup() {
  if [[ -n "$BACKUP" && -f "$BACKUP" ]]; then
    mv "$BACKUP" "$OVERRIDES"
  else
    rm -f "$OVERRIDES"
  fi
  if [[ -n "$LOCK_BACKUP" && -f "$LOCK_BACKUP" ]]; then
    mv "$LOCK_BACKUP" "$LOCKFILE"
  fi
  if command -v flutter >/dev/null 2>&1; then
    flutter pub get >/dev/null || true
  fi
}
trap cleanup EXIT

if [[ -f "$LOCKFILE" ]]; then
  LOCK_BACKUP="$(mktemp "$ROOT_DIR/pubspec.lock.XXXXXX")"
  cp "$LOCKFILE" "$LOCK_BACKUP"
fi

if [[ -f "$OVERRIDES" ]]; then
  BACKUP="$(mktemp "$ROOT_DIR/pubspec_overrides.yaml.XXXXXX")"
  mv "$OVERRIDES" "$BACKUP"
fi

cp "$NOGMS_OVERRIDES" "$OVERRIDES"

flutter pub get
flutter build apk \
  --flavor noGms \
  --dart-define=NO_GMS=true \
  "$@"
