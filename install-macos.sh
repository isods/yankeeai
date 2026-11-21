#!/usr/bin/env bash
#
# Install the YankeeAI desktop app on macOS.
#
# The release DMG is fetched with curl rather than a browser. Browsers attach the
# com.apple.quarantine extended attribute to downloads (via LSFileQuarantineEnabled
# in their Info.plist), and Gatekeeper only runs its first-launch assessment on
# quarantined files. Command-line network tools such as curl are exempt, so the
# installed app starts without the "unidentified developer" prompt.
#
# The app is ad-hoc signed (bundle.macOS.signingIdentity = "-"), which is what
# allows arm64 code to execute at all on Apple Silicon.
#
# Usage:
#   ./install-macos.sh                    # latest release
#   ./install-macos.sh 1.0.1              # specific version
#   ./install-macos.sh --dir "$HOME/Applications"
#   ./install-macos.sh --yes              # non-interactive replacement
#
set -euo pipefail

REPO="${YANKEEAI_REPO:-isods/yankeeai}"
INSTALL_DIR="/Applications"
VERSION=""
ASSUME_YES=0
SKIP_CHECKSUM=0

WORK_DIR=""
MOUNT_POINT=""
MOUNTED=0

log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Install the YankeeAI desktop app on macOS.

Usage: install-macos.sh [VERSION] [options]

Arguments:
  VERSION              Release tag to install, e.g. 1.0.1. Defaults to the
                       latest published release.

Options:
  -d, --dir DIR        Install location. Defaults to /Applications.
  -y, --yes            Replace an existing installation without prompting.
      --skip-checksum  Do not verify the DMG against SHA256SUMS.txt.
  -h, --help           Show this help.

Environment:
  YANKEEAI_REPO        Override the GitHub repository (owner/name).
  GITHUB_TOKEN         Use a token for the GitHub API, avoiding rate limits.
EOF
}

# Prompts read from /dev/tty so the script still works when piped from curl,
# where stdin is the script itself rather than the terminal.
confirm() {
  [[ "$ASSUME_YES" -eq 1 ]] && return 0
  local reply
  # /dev/tty can exist yet be unusable, so probe it rather than testing for it.
  if ! { printf '%s [y/N] ' "$1" >/dev/tty; } 2>/dev/null; then
    die "cannot prompt without a terminal; pass --yes to proceed"
  fi
  read -r reply </dev/tty 2>/dev/null || return 1
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

cleanup() {
  if [[ "$MOUNTED" -eq 1 && -n "$MOUNT_POINT" ]]; then
    hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null ||
      hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null || true
  fi
  [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
  return 0
}
trap cleanup EXIT

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d | --dir)
        [[ $# -ge 2 ]] || die "--dir requires a value"
        INSTALL_DIR="$2"
        shift 2
        ;;
      -y | --yes)
        ASSUME_YES=1
        shift
        ;;
      --skip-checksum)
        SKIP_CHECKSUM=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -*) die "unknown option: $1 (try --help)" ;;
      *)
        [[ -z "$VERSION" ]] || die "unexpected extra argument: $1"
        VERSION="$1"
        shift
        ;;
    esac
  done
}

detect_arch() {
  case "$(uname -m)" in
    arm64) echo "aarch64" ;;
    x86_64) echo "x64" ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

api_get() {
  local url="$1" out="$2"
  local -a headers=(-H "Accept: application/vnd.github+json")
  [[ -n "${GITHUB_TOKEN:-}" ]] && headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")

  if ! curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 \
    "${headers[@]}" "$url" -o "$out"; then
    return 1
  fi
}

# Tauri names macOS DMGs "<productName>_<version>_<arch>.dmg", where arch is
# "x64" for Intel and "aarch64" for Apple Silicon.
resolve_assets() {
  local arch="$1" json="$2"
  local urls dmg_url sums_url

  urls=$(grep -o '"browser_download_url":[[:space:]]*"[^"]*"' "$json" |
    sed -E 's/.*"(https?[^"]*)".*/\1/') || true
  [[ -n "$urls" ]] || die "release has no downloadable assets"

  dmg_url=$(printf '%s\n' "$urls" | grep -E "_${arch}\.dmg$" | head -n1) || true
  [[ -n "$dmg_url" ]] || die "release has no ${arch} DMG asset"

  sums_url=$(printf '%s\n' "$urls" | grep -E '/SHA256SUMS\.txt$' | head -n1) || true

  printf '%s\n%s\n' "$dmg_url" "$sums_url"
}

verify_checksum() {
  local sums="$1" dmg_path="$2" name="$3"
  local expected actual

  expected=$(awk -v name="$name" '$2 == name { print $1 }' "$sums" | head -n1)
  [[ -n "$expected" ]] || die "$name is not listed in SHA256SUMS.txt"

  actual=$(shasum -a 256 "$dmg_path" | awk '{print $1}')
  if [[ "$actual" != "$expected" ]]; then
    die "checksum mismatch for $name
  expected: $expected
  actual:   $actual"
  fi
  log "Checksum verified ($actual)"
}

app_is_running() {
  pgrep -f "$1/Contents/MacOS/" >/dev/null 2>&1
}

# Release tags may or may not carry a "v" prefix, so accept either spelling of
# whatever version the user supplies.
resolve_release() {
  local version="$1" json="$2"
  local -a tags=()

  if [[ -n "$version" ]]; then
    tags+=("$version")
    if [[ "$version" == v* ]]; then
      tags+=("${version#v}")
    else
      tags+=("v$version")
    fi
  fi

  if [[ "${#tags[@]}" -eq 0 ]]; then
    api_get "https://api.github.com/repos/${REPO}/releases/latest" "$json"
    return
  fi

  # A miss on the first spelling is expected, so keep its curl error out of the
  # output; the caller reports a clear failure if every candidate misses.
  local tag
  for tag in "${tags[@]}"; do
    if api_get "https://api.github.com/repos/${REPO}/releases/tags/${tag}" "$json" 2>/dev/null; then
      log "Resolved release ${tag}"
      return 0
    fi
  done
  return 1
}

main() {
  parse_args "$@"

  [[ "$(uname -s)" == "Darwin" ]] || die "this installer is for macOS only"
  command -v hdiutil >/dev/null || die "hdiutil not found; this does not look like macOS"

  local arch
  arch=$(detect_arch)
  log "Target: ${arch} (host $(uname -m)), repo ${REPO}"

  WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/yankeeai-install.XXXXXX")

  if [[ -n "$VERSION" ]]; then
    log "Resolving release ${VERSION}"
  else
    log "Resolving latest release"
  fi

  local json="${WORK_DIR}/release.json"
  if ! resolve_release "$VERSION" "$json"; then
    die "could not resolve ${VERSION:-the latest release} from ${REPO}
Check that the version exists and that the release is published; draft releases are not visible without a token."
  fi

  # Command substitution rather than process substitution so that a failure
  # inside resolve_assets propagates and aborts under `set -e`.
  local assets dmg_url sums_url
  assets=$(resolve_assets "$arch" "$json")
  dmg_url=$(printf '%s\n' "$assets" | sed -n '1p')
  sums_url=$(printf '%s\n' "$assets" | sed -n '2p')

  local dmg_name="${dmg_url##*/}"
  local dmg_path="${WORK_DIR}/${dmg_name}"
  log "Downloading ${dmg_name}"
  curl -fL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 \
    --progress-bar "$dmg_url" -o "$dmg_path" ||
    die "download failed: ${dmg_url}"

  if [[ "$SKIP_CHECKSUM" -eq 1 ]]; then
    warn "skipping checksum verification"
  elif [[ -z "$sums_url" ]]; then
    die "release has no SHA256SUMS.txt; re-run with --skip-checksum to bypass"
  else
    local sums_path="${WORK_DIR}/SHA256SUMS.txt"
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "$sums_url" -o "$sums_path" ||
      die "could not download SHA256SUMS.txt"
    verify_checksum "$sums_path" "$dmg_path" "$dmg_name"
  fi

  MOUNT_POINT="${WORK_DIR}/mnt"
  mkdir -p "$MOUNT_POINT"
  log "Mounting disk image"
  hdiutil attach "$dmg_path" -nobrowse -readonly -quiet -mountpoint "$MOUNT_POINT" ||
    die "could not mount ${dmg_name}"
  MOUNTED=1

  local src_app
  src_app=$(find "$MOUNT_POINT" -maxdepth 1 -name '*.app' -print -quit)
  [[ -n "$src_app" ]] || die "no .app bundle found inside ${dmg_name}"

  local app_name target_app
  app_name=$(basename "$src_app")
  target_app="${INSTALL_DIR%/}/${app_name}"

  if app_is_running "$target_app"; then
    die "${app_name} is running; quit it and run this installer again"
  fi

  if [[ -e "$target_app" ]]; then
    if ! confirm "Replace existing ${target_app}?"; then
      die "aborted at user request"
    fi
    log "Removing existing installation"
    if [[ -w "$INSTALL_DIR" ]]; then
      rm -rf "$target_app"
    else
      sudo rm -rf "$target_app"
    fi
  fi

  mkdir -p "$INSTALL_DIR" 2>/dev/null ||
    sudo mkdir -p "$INSTALL_DIR"

  log "Installing to ${target_app}"
  if [[ -w "$INSTALL_DIR" ]]; then
    ditto "$src_app" "$target_app"
  else
    sudo ditto "$src_app" "$target_app"
  fi

  # Belt and braces: a DMG fetched by a browser carries the quarantine attribute,
  # which would propagate to the copied bundle.
  xattr -dr com.apple.quarantine "$target_app" 2>/dev/null ||
    sudo xattr -dr com.apple.quarantine "$target_app" 2>/dev/null || true

  if codesign --verify --deep --strict "$target_app" >/dev/null 2>&1; then
    log "Signature OK ($(codesign -dv "$target_app" 2>&1 | grep -E '^Signature=' || echo 'adhoc'))"
  else
    warn "code signature did not validate; the app may refuse to launch on Apple Silicon"
  fi

  cat <<EOF

Installed ${app_name} to ${target_app}

Open it with:
  open "${target_app}"
EOF
}

main "$@"
