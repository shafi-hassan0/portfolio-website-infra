# Portfolio Deployment Infra

The deployment and CI/CD orchestration layer behind [shafihassan.com](https://shafihassan.com). This repo doesn't hold application code — it holds the Docker Compose stack, the reverse proxy config, and the GitHub Actions pipelines that deploy the [API](https://github.com/shafi-hassan0/portfolio-website-api) and [UI](https://github.com/shafi-hassan0/portfolio-website-ui) repos to a home server and verify the deploy actually worked.

**Live:** [shafihassan.com](https://shafihassan.com)

## Highlights

- Runs on a home server, exposed to the internet with a **Cloudflare Tunnel** — no inbound ports opened, no public IP required
- **Docker Compose** stack: Node/Express backend, Nginx serving the built Angular frontend, and `cloudflared` for the tunnel
- Deploys are triggered automatically by a push to either app repo via `repository_dispatch`, then this repo dispatches the matching test suite ([API tests](https://github.com/shafi-hassan0/portfolio-website-api-tests) or [UI tests](https://github.com/shafi-hassan0/portfolio-website-ui-tests)) and **waits for the real result** — its own GitHub Actions job only shows green if the tests actually passed, not just that they were triggered
- SSH access for deploys is itself gated behind Cloudflare Access, authenticated in CI with a service token rather than an exposed SSH port

---

## For Developers

### Layout

This repo expects to sit alongside the two app repos on the server:

```
shafi/
├── portfolio-website-infra/   (this repo)
├── portfolio-website-api/
└── portfolio-website-ui/
```

### Key files

- `docker-compose.yml` — the `backend`, `web` (Nginx), and `cloudflared` services
- `deploy.sh` — pulls and rebuilds a given target (`frontend`, `backend`, or `infra`)
- `.github/workflows/deploy-backend.yml` / `deploy-frontend.yml` — triggered by `repository_dispatch` from the app repos; SSH into the server via Cloudflare Access, run `deploy.sh`, then dispatch-and-wait on the corresponding test suite
- `.github/actions/dispatch-and-wait/` — composite action shared by both deploy workflows: fires a `repository_dispatch` at the test repo, polls for the resulting run, and fails the job if that run didn't succeed

### Deploying manually

```bash
./deploy.sh backend    # rebuild + restart the API container
./deploy.sh frontend   # pull, build, and restart Nginx with the new bundle
./deploy.sh infra      # bring up docker-compose.yml as-is
```

### Required secrets

`DEPLOY_SSH_KEY`, `CF_ACCESS_CLIENT_ID`, `CF_ACCESS_CLIENT_SECRET`, `SSH_HOSTNAME`, `SSH_USER`, `DEPLOY_PATH`, `API_TESTS_DISPATCH_TOKEN`, `UI_TESTS_DISPATCH_TOKEN`.
