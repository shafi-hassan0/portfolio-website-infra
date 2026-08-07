#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Backstop against overlapping deploys (e.g. a manual run alongside a CI
# trigger) racing on this repo's own git refs when both run `git pull` below.
exec 200>"$ROOT/.deploy.lock"
flock -w 300 200 || {
  echo "Could not acquire deploy lock within 5 minutes" >&2
  exit 1
}

API_DIR="$ROOT/../portfolio-website-api"
UI_DIR="$ROOT/../portfolio-website-ui"

# Non-interactive SSH commands (e.g. from CI) don't source ~/.bashrc, so nvm's
# node/npm never make it onto PATH there even though they do in a normal login shell.
export PATH="/home/nixy/.nvm/versions/node/v24.19.0/bin:$PATH"

TARGET="${1:-}"
MODE="${2:-}"

usage() {
  echo "Usage:"
  echo "  ./deploy.sh frontend"
  echo "  ./deploy.sh backend"
  echo "  ./deploy.sh backend seed"
  echo "  ./deploy.sh infra"
  exit 1
}

case "$TARGET" in
  frontend|backend|infra) ;;
  *) usage ;;
esac

echo "=== Pulling latest (infra) ==="
git pull

case "$TARGET" in
  frontend)
    echo "=== Pulling latest (ui) ==="
    git -C "$UI_DIR" pull

    echo "=== Building frontend ==="
    (cd "$UI_DIR" && npm run build)

    echo "=== Restarting web container ==="
    docker compose restart web

    echo
    echo "Done. Frontend deployed."
    ;;
  backend)
    echo "=== Pulling latest (api) ==="
    git -C "$API_DIR" pull

    echo "=== Rebuilding and restarting backend container ==="
    docker compose up -d --build backend

    if [ "$MODE" = "seed" ]; then
      echo "=== Seeding database ==="
      docker compose exec backend node dist/seed/seed.js
    fi

    echo
    echo "Done. Backend deployed."
    ;;
  infra)
    echo "=== Applying infra changes ==="
    docker compose up -d

    echo
    echo "Done. Infra deployed."
    ;;
  *)
    usage
    ;;
esac
