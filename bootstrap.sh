#!/usr/bin/env bash
set -euo pipefail

ORG="einky"
# Active repos. `os` (pi-gen) is archived and intentionally omitted — the device
# OS is now `buildroot_os` (Buildroot/InkyOS). See adr/0007-buildroot-os.md.
REPOS=(.github docs buildroot_os runtime launcher server web case games)

PROTO="ssh"
for arg in "$@"; do
    case "$arg" in
        --ssh)   PROTO="ssh" ;;
        --https) PROTO="https" ;;
        -h|--help)
            cat <<EOF
Usage: $(basename "$0") [--ssh|--https]

Clones every Crab-Ink-Gaming repo (except meta) into ../ as siblings of
this repo. Already-cloned repos are skipped.

  --https   use https remotes (default)
  --ssh     use ssh remotes
EOF
            exit 0
            ;;
        *)
            echo "unknown argument: $arg" >&2
            exit 2
            ;;
    esac
done

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PARENT_DIR=$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)

remote_url() {
    local repo="$1"
    if [ "$PROTO" = "ssh" ]; then
        echo "git@github.com:${ORG}/${repo}.git"
    else
        echo "https://github.com/${ORG}/${repo}.git"
    fi
}

cloned=()
skipped=()
failed=()

echo "Bootstrapping Crab-Ink-Gaming workspace into: $PARENT_DIR"
echo "Protocol: $PROTO"
echo

for repo in "${REPOS[@]}"; do
    target="$PARENT_DIR/$repo"
    url=$(remote_url "$repo")

    if [ -d "$target/.git" ]; then
        echo "[skip]  $repo (already cloned at $target)"
        skipped+=("$repo")
        continue
    fi

    if [ -e "$target" ]; then
        echo "[fail]  $repo: $target exists but is not a git repo" >&2
        failed+=("$repo")
        continue
    fi

    echo "[clone] $repo  ←  $url"
    if git clone "$url" "$target"; then
        cloned+=("$repo")
    else
        echo "[fail]  $repo: clone failed" >&2
        failed+=("$repo")
    fi
done

echo
echo "──────── Summary ────────"
printf '  cloned:  %d  %s\n' "${#cloned[@]}"  "${cloned[*]:-}"
printf '  skipped: %d  %s\n' "${#skipped[@]}" "${skipped[*]:-}"
printf '  failed:  %d  %s\n' "${#failed[@]}"  "${failed[*]:-}"

if [ ${#failed[@]} -gt 0 ]; then
    exit 1
fi
