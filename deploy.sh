#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

TARGET="${1:-}"
MODE="${2:-}"

usage() {
  echo "Usage:"
  echo "  ./deploy.sh frontend"
  echo "  ./deploy.sh backend"
  echo "  ./deploy.sh backend seed"
  exit 1
}

case "$TARGET" in
  frontend)
    echo "=== Building frontend ==="
    cd "$ROOT/frontend"
    npm run build
    cd "$ROOT"

    echo "=== Restarting web container ==="
    docker compose restart web

    echo
    echo "Done. Frontend deployed."
    ;;
  backend)
    echo "=== Rebuilding and restarting backend container ==="
    docker compose up -d --build backend

    if [ "$MODE" = "seed" ]; then
      echo "=== Seeding database ==="
      docker compose exec backend node dist/seed/seed.js
    fi

    echo
    echo "Done. Backend deployed."
    ;;
  *)
    usage
    ;;
esac
