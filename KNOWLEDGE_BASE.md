# Project Knowledge Base

Last updated: 2026-05-15

---

## Architecture

```
Browser ──HTTPS──► Cloudflare (Flexible SSL) ──HTTP──► DO Droplet (167.99.148.22) :80
                                                         │
                                                    nginx (docker)
                                                    ┌──────────────┐
                                                    │ translatemethod.com → bidirectional-translations:4000 (Phoenix)
                                                    │ wrightdavid.com     → frontend:80 (Angular) + backend:8888 (Node/Java)
                                                    │ yoloresponsibly.com  → kelly-criterion:80
                                                    └──────────────┘
                                                         │
                                                    Docker DNS (internal)
                                                         │
                                                    PostgreSQL ──→ Neon cloud (free tier)
                                                    Email ───────→ Resend (free tier)
```

## Infrastructure

| Service | Provider | Tier | Notes |
|---|---|---|---|
| VPS | DigitalOcean | $6/mo droplet | 1 vCPU, 1 GB RAM, Ubuntu |
| Database | Neon | Free | 0.5 GB storage, serverless Postgres, `us-east-1` |
| Email | Resend | Free | 100 emails/day |
| DNS/SSL | Cloudflare | Free | Flexible SSL mode (HTTPS → HTTP to origin) |
| Docker images | Docker Hub | Free | `bloodisblue/*` |
| Reverse proxy | nginx (Docker) | — | Single `nginx.conf` routes all domains |

## Deploy Flow

### Phoenix App (bidirectional_translations)

```bash
# 1. Build & push Docker image (from laptop)
cd ~/code/bidirectional_translations
./deploy.sh 1.X.Y    # builds assets natively, then builds + pushes Docker image

# 2. Deploy on droplet
ssh droplet
cd ~/blog-server
# Update docker-compose.yml tag to :1.X.Y
docker-compose pull bidirectional-translations
docker-compose up -d bidirectional-translations
docker-compose exec bidirectional-translations /app/bin/migrate
```

### Angular Blog (wrightdavid.com)

```bash
cd ~/code/blog-angular
docker build -t bloodisblue/my-blog:1.X.Y .
docker push bloodisblue/my-blog:1.X.Y
# Update docker-compose.yml tag, then on droplet:
docker-compose pull frontend && docker-compose up -d frontend
```

### All services on droplet

```bash
cd ~/blog-server
./deploy.sh    # pulls latest images, starts all services, runs migrations
```

## Docker Build — ARM Mac → x86 Droplet

**Problem**: Docker builds for `linux/amd64` on Apple Silicon use QEMU emulation, which causes multiple issues.

**Fixes applied** (in `Dockerfile`):

```dockerfile
# 1. Prevent OOM during Elixir compilation
ENV ERL_FLAGS="+JPperf true"

# 2. Build assets natively on Mac, copy into Docker
# (tailwind v4 is Bun-compiled — Bun breaks under QEMU)
# deploy.sh runs `mix assets.deploy` BEFORE `docker build`

# 3. Allow pre-built assets into Docker context
# Removed from .dockerignore: /priv/static/assets/, /priv/static/cache_manifest.json
```

**Build command** (in `deploy.sh`):
```bash
docker build --platform linux/amd64 -t bloodisblue/bidirectional-translations:X.Y .
```

## Environment Variables

### .env file on droplet (`/root/blog-server/.env`)

```bash
DATABASE_URL=postgresql://neondb_owner:XXX@ep-...aws.neon.tech/neondb?sslmode=require
SECRET_KEY_BASE=<from mix phx.gen.secret>
PHX_HOST=translatemethod.com
RESEND_API_KEY=re_XXX
```

### .env file locally (`bidirectional_translations/.env`)

```bash
DATABASE_URL=postgresql://neondb_owner:XXX@ep-...aws.neon.tech/neondb?sslmode=require
RESEND_API_KEY=re_XXX
```

- `.env` is gitignored in both projects
- `config/dev.exs` auto-loads `.env` at startup
- Old docker-compose v1 (1.29.2) on droplet — use `docker-compose` not `docker compose`

## Key Config Files

| File | Location | Purpose |
|---|---|---|
| `docker-compose.yml` | `blog-angular/hosting_scripts/` | All services + nginx |
| `nginx.conf` | `blog-angular/hosting_scripts/nginx/` | Reverse proxy for all domains |
| `.env` | `blog-angular/hosting_scripts/` | Secrets (gitignored) |
| `deploy.sh` | `bidirectional_translations/` | Build & push Phoenix Docker image |
| `Dockerfile` | `bidirectional_translations/` | Phoenix release build |
| `.dockerignore` | `bidirectional_translations/` | **Do NOT** exclude priv/static/assets/ |

## Production Gotchas

### Mix is not available in releases
- `Mix.env()` crashes at boot in `:prod`
- Use `Application.compile_env/3` or remove the conditional

### Phoenix force_ssl + nginx
- nginx proxy needs `proxy_set_header X-Forwarded-Proto https;`
- Cloudflare Flexible SSL: browser→HTTPS→Cloudflare→HTTP→droplet→nginx→Phoenix

### LiveView WebSocket + nginx
- Requires `proxy_http_version 1.1;`
- Requires `proxy_set_header Upgrade $http_upgrade;`
- Requires `proxy_set_header Connection "upgrade";`

### Database SSL
- `config :repo, ssl: true` is required for Neon
- Also works with `?sslmode=require` in DATABASE_URL

### Docker DNS
- Containers communicate via service names (not IPs)
- Docker's embedded DNS at `127.0.0.11` resolves service names
- No need for `ports:` on app services — only nginx exposes ports

## Useful Droplet Commands

```bash
# Check all containers
docker-compose ps

# Logs
docker-compose logs bidirectional-translations --tail=50
docker-compose logs -f nginx

# Restart one service
docker-compose restart nginx

# Run migrations
docker-compose exec bidirectional-translations /app/bin/migrate

# Shell into a container
docker-compose exec nginx sh

# Test nginx routing
curl -s -H "Host: translatemethod.com" http://localhost:80/
```

## Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---|---|---|
| 502 Bad Gateway | Container crashed or restarting | `docker-compose logs <service>` |
| 521 (Cloudflare) | Cloudflare can't reach origin | Check DNS A record → droplet IP; SSL mode = Flexible |
| Redirect loop | `X-Forwarded-Proto: http` | Set to `https` in nginx |
| LiveView spinner forever | WebSocket blocked | `proxy_http_version 1.1;` in nginx |
| `Mix.env/0 is undefined` | Release build | Remove `Mix.env()` from application.ex |
| `exec format error` | ARM image on x86 | Build with `--platform linux/amd64` |
| OOM during build | QEMU memory ballooning | `ERL_FLAGS="+JPperf true"` |
| CSS/JS 404 | tailwind/Bun fails under QEMU | Pre-build assets natively |
| Assets missing in Docker | `.dockerignore` blocking | Don't ignore `priv/static/assets/` |
