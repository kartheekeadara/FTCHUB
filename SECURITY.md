# FTCHUB Security Guide

## Secret handling matrix

| Secret | Client (iOS) | Server (Edge Functions / CI) | Notes |
|--------|--------------|------------------------------|-------|
| Supabase anon key | Yes | No | Protected by RLS; bundle via `Secrets.plist` |
| Supabase service_role | **Never** | Yes | Edge Functions (`SERVICE_ROLE_KEY`), GitHub Actions |
| Google iOS OAuth client ID | Yes (public) | No | Same value in `Secrets.plist` and Xcode build settings |
| Google web client secret | No | Supabase Dashboard only | |
| Shopify Storefront token | No | GitHub Actions only | |
| User session JWT | Runtime only | No | |

## Rotating the Supabase service_role key

If a service_role key was ever committed to git, treat it as compromised.

1. Supabase Dashboard → **Settings** → **API** → rotate **service_role** key.
2. Update local/CI env: `SUPABASE_SERVICE_ROLE_KEY`.
3. Redeploy Edge Function secrets: `./deploy-edge-function.sh` (requires env vars; see `deploy-edge-function.sh.example`).
4. Update GitHub repository secret `SUPABASE_SERVICE_ROLE_KEY` for the Shopify catalog workflow.

## Deploying Edge Functions

```bash
export SUPABASE_PROJECT_REF="your-project-ref"
export SUPABASE_URL="https://your-project-ref.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
./deploy-edge-function.sh
```

## Database migrations

Apply migrations in [`supabase/migrations/`](supabase/migrations/) via the Supabase CLI or SQL editor. Historical reference scripts live in [`docs/database/archive/`](docs/database/archive/).

## Rate limiting

| Layer | Mechanism |
|-------|-----------|
| Edge Functions | Postgres `check_rate_limit` RPC; HTTP 429 + `Retry-After` |
| Supabase Auth | Dashboard / [`supabase/config.toml`](supabase/config.toml) `[auth.rate_limit]` |
| iOS auth flows | `SecurityUtils.checkRateLimit` in `AuthService` |
| PostgREST | Platform limits + RLS |

## OWASP API alignment (summary)

- **Broken authentication**: Auth rate limits, password policy, client brute-force guard.
- **Unrestricted resource consumption**: Edge 429, auth limits, `max_rows`.
- **Broken object level authorization**: RLS on team data; new policies on consent/reports.
- **Unsafe API consumption**: `InputValidator` + Zod on Edge Functions.
- **Security misconfiguration**: No secrets in repo; env-based deploy script.

## Optional: captcha

Enable `[auth.captcha]` in `supabase/config.toml` (Turnstile or hCaptcha) for additional sign-up protection.

## Secret scanning

CI runs [gitleaks](.github/workflows/gitleaks.yml) on push/PR to block accidental secret commits.
