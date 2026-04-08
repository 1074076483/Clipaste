#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_NAME="${APP_NAME:-Clipaste}"
RELEASE_TAG="${RELEASE_TAG:-}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
GH_TOKEN="${GH_TOKEN:-}"
SPARKLE_PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:-}"
SPARKLE_KEY_ACCOUNT="${SPARKLE_KEY_ACCOUNT:-clipaste}"
SPARKLE_VERSION="${SPARKLE_VERSION:-2.9.1}"
DIST_DIR="${DIST_DIR:-$PROJECT_ROOT/build/release}"
BUILD_ROOT="${BUILD_ROOT:-$PROJECT_ROOT/build}"
FEED_BRANCH="${FEED_BRANCH:-update-feed}"
FEED_DIR="${FEED_DIR:-$BUILD_ROOT/update-feed}"
SPARKLE_SOURCE_DIR="${SPARKLE_SOURCE_DIR:-$BUILD_ROOT/sparkle-tools-src}"
SPARKLE_DERIVED_DATA_PATH="${SPARKLE_DERIVED_DATA_PATH:-$BUILD_ROOT/DerivedData-SparkleTools}"
RELEASE_NOTES_MARKDOWN="${RELEASE_NOTES_MARKDOWN:-}"

if [[ -z "$RELEASE_TAG" ]]; then
  echo "RELEASE_TAG is required." >&2
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "GITHUB_REPOSITORY is required." >&2
  exit 1
fi

if [[ -z "$GH_TOKEN" ]]; then
  echo "GH_TOKEN is required." >&2
  exit 1
fi

if [[ -z "$SPARKLE_PRIVATE_KEY" ]]; then
  echo "SPARKLE_PRIVATE_KEY is required." >&2
  exit 1
fi

ZIP_PATH="${ZIP_PATH:-$DIST_DIR/${APP_NAME}-${RELEASE_TAG}.zip}"
if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Unable to locate ZIP update archive at $ZIP_PATH." >&2
  exit 1
fi

ARTIFACT_BASENAME="$(basename "$ZIP_PATH" .zip)"
DOWNLOAD_URL_PREFIX="https://github.com/${GITHUB_REPOSITORY}/releases/download/${RELEASE_TAG}/"
FULL_RELEASE_NOTES_URL="https://github.com/${GITHUB_REPOSITORY}/releases/tag/${RELEASE_TAG}"
APP_LINK="https://github.com/${GITHUB_REPOSITORY}"
REMOTE_URL="https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

prepare_feed_checkout() {
  rm -rf "$FEED_DIR"

  if git ls-remote --exit-code --heads "$REMOTE_URL" "$FEED_BRANCH" >/dev/null 2>&1; then
    git clone --depth 1 --branch "$FEED_BRANCH" "$REMOTE_URL" "$FEED_DIR"
  else
    git clone --depth 1 "$REMOTE_URL" "$FEED_DIR"
    git -C "$FEED_DIR" checkout --orphan "$FEED_BRANCH"
    find "$FEED_DIR" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  fi
}

ensure_sparkle_tools() {
  if [[ -x "$SPARKLE_DERIVED_DATA_PATH/Build/Products/Release/generate_appcast" ]]; then
    return
  fi

  rm -rf "$SPARKLE_SOURCE_DIR"
  git clone --depth 1 --branch "$SPARKLE_VERSION" https://github.com/sparkle-project/Sparkle "$SPARKLE_SOURCE_DIR"
  xcodebuild \
    -project "$SPARKLE_SOURCE_DIR/Sparkle.xcodeproj" \
    -scheme generate_appcast \
    -configuration Release \
    -derivedDataPath "$SPARKLE_DERIVED_DATA_PATH" \
    build
}

prepare_feed_checkout
ensure_sparkle_tools

cp "$ZIP_PATH" "$FEED_DIR/"
printf '%s\n' "${RELEASE_NOTES_MARKDOWN:-$RELEASE_TAG}" > "$FEED_DIR/${ARTIFACT_BASENAME}.md"
touch "$FEED_DIR/.nojekyll"

printf '%s' "$SPARKLE_PRIVATE_KEY" | \
  "$SPARKLE_DERIVED_DATA_PATH/Build/Products/Release/generate_appcast" \
    --ed-key-file - \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    --embed-release-notes \
    --full-release-notes-url "$FULL_RELEASE_NOTES_URL" \
    --link "$APP_LINK" \
    --maximum-deltas 0 \
    --maximum-versions 3 \
    "$FEED_DIR"

rm -rf "$FEED_DIR/old_updates"

git -C "$FEED_DIR" config user.name "github-actions[bot]"
git -C "$FEED_DIR" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git -C "$FEED_DIR" add -A

if git -C "$FEED_DIR" diff --cached --quiet; then
  echo "Sparkle feed is already up to date."
  exit 0
fi

git -C "$FEED_DIR" commit -m "Update Sparkle feed for $RELEASE_TAG"
git -C "$FEED_DIR" push origin "$FEED_BRANCH"
