#!/usr/bin/env sh
set -eu

ROOT_DIR="${RINOIMOB_ROOT_DIR:-/opt/rinoimob}"
BRANCH="${RINOIMOB_BRANCH:-main}"

REPOS="
rinoimob-backend
rinoimob-app
rinoimob-website
rinoimob-infrastructure
"

usage() {
    cat <<EOF
Usage: $0 [--force-clean]

Environment:
  RINOIMOB_ROOT_DIR   Base directory containing the Rinoimob repositories.
                     Default: /opt/rinoimob
  RINOIMOB_BRANCH     Branch to update.
                     Default: main

Options:
  --force-clean       Discard local uncommitted changes and remove untracked files
                     before pulling. Use only on the server deploy checkout.
EOF
}

FORCE_CLEAN=0
case "${1:-}" in
    "")
        ;;
    "--force-clean")
        FORCE_CLEAN=1
        ;;
    "-h"|"--help")
        usage
        exit 0
        ;;
    *)
        usage
        exit 2
        ;;
esac

if ! command -v git >/dev/null 2>&1; then
    echo "git is required but was not found in PATH." >&2
    exit 1
fi

echo "Updating Rinoimob repositories"
echo "Root:   $ROOT_DIR"
echo "Branch: $BRANCH"
echo

for repo in $REPOS; do
    repo_dir="$ROOT_DIR/$repo"
    if [ ! -d "$repo_dir/.git" ]; then
        echo "Missing git repository: $repo_dir" >&2
        exit 1
    fi
done

for repo in $REPOS; do
    repo_dir="$ROOT_DIR/$repo"
    echo "==> $repo"

    if [ "$FORCE_CLEAN" -eq 1 ]; then
        git -C "$repo_dir" reset --hard
        git -C "$repo_dir" clean -fd
    else
        if [ -n "$(git -C "$repo_dir" status --porcelain)" ]; then
            echo "Refusing to pull because $repo has local changes." >&2
            echo "Run with --force-clean only if this server checkout has no work to keep." >&2
            exit 1
        fi
    fi

    git -C "$repo_dir" fetch origin "$BRANCH"
    git -C "$repo_dir" checkout "$BRANCH"
    git -C "$repo_dir" pull --ff-only origin "$BRANCH"
    git -C "$repo_dir" status --short --branch
    echo
done

echo "All repositories are up to date."
