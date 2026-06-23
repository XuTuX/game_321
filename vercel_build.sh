#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLUTTER_DIR="${FLUTTER_DIR:-$PROJECT_DIR/.flutter-sdk}"

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
else
  if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
    git clone --depth 1 --branch stable \
      https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
  FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"
fi

cd "$PROJECT_DIR"
"$FLUTTER_BIN" config --enable-web
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build web --release --base-href /
