#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  PLATFORMS=(web)
elif [[ "$1" == "all" ]]; then
  PLATFORMS=(web apk appbundle ios macos linux windows)
else
  PLATFORMS=("$@")
fi

for portal in public admin merchant staff; do
  echo
  echo "===== Building portal $portal ====="
  ./build-portal.sh "$portal" "${PLATFORMS[@]}"
done

echo "All portal builds completed."
