// OWASP API4:2023 — Unrestricted Resource Consumption
// Postgres-backed IP and user rate limiting for Edge Functions (graceful 429).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
}

export type RateLimitConfig = {
  endpoint: string
  ipMax: number
  ipWindowSeconds: number
  userMax?: number
  userWindowSeconds?: number
}

/** Extract client IP from proxy headers (first hop). */
export function getClientIP(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for")
  if (forwarded) {
    const first = forwarded.split(",")[0]?.trim()
    if (first) return first.slice(0, 128)
  }
  const cf = req.headers.get("cf-connecting-ip")
  if (cf) return cf.slice(0, 128)
  return "unknown"
}

function adminClient() {
  return createClient(
    Deno.env.get("PROJECT_URL") ?? "",
    Deno.env.get("SERVICE_ROLE_KEY") ?? "",
    { auth: { autoRefreshToken: false, persistSession: false } },
  )
}

async function checkScope(
  scope: "ip" | "user",
  identifier: string,
  endpoint: string,
  maxRequests: number,
  windowSeconds: number,
): Promise<{ allowed: boolean; retryAfterSeconds: number }> {
  const supabase = adminClient()
  const { data, error } = await supabase.rpc("check_rate_limit", {
    p_scope: scope,
    p_identifier: identifier,
    p_endpoint: endpoint,
    p_max_requests: maxRequests,
    p_window_seconds: windowSeconds,
  })

  if (error) {
    console.error("rate_limit_rpc_error", error.message)
    // Fail open to avoid blocking legitimate traffic on DB errors
    return { allowed: true, retryAfterSeconds: 0 }
  }

  const row = Array.isArray(data) ? data[0] : data
  return {
    allowed: row?.allowed ?? true,
    retryAfterSeconds: row?.retry_after_seconds ?? 60,
  }
}

/** Returns a 429 Response when limited; null when allowed. */
export async function enforceRateLimit(
  req: Request,
  config: RateLimitConfig,
  userId?: string | null,
): Promise<Response | null> {
  const ip = getClientIP(req)

  const ipResult = await checkScope(
    "ip",
    ip,
    config.endpoint,
    config.ipMax,
    config.ipWindowSeconds,
  )
  if (!ipResult.allowed) {
    return rateLimitResponse(ipResult.retryAfterSeconds)
  }

  if (userId && config.userMax && config.userWindowSeconds) {
    const userResult = await checkScope(
      "user",
      userId,
      config.endpoint,
      config.userMax,
      config.userWindowSeconds,
    )
    if (!userResult.allowed) {
      return rateLimitResponse(userResult.retryAfterSeconds)
    }
  }

  return null
}

/** Per-user limit only (after JWT validation). */
export async function enforceUserRateLimit(
  req: Request,
  config: RateLimitConfig,
  userId: string,
): Promise<Response | null> {
  if (!config.userMax || !config.userWindowSeconds) {
    return null
  }
  const userResult = await checkScope(
    "user",
    userId,
    config.endpoint,
    config.userMax,
    config.userWindowSeconds,
  )
  if (!userResult.allowed) {
    return rateLimitResponse(userResult.retryAfterSeconds)
  }
  return null
}

export function rateLimitResponse(retryAfterSeconds: number): Response {
  const retry = Math.max(1, Math.ceil(retryAfterSeconds))
  return new Response(
    JSON.stringify({
      error: "Too many requests",
      retryAfterSeconds: retry,
    }),
    {
      status: 429,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "Retry-After": String(retry),
      },
    },
  )
}

export function jsonResponse(
  body: unknown,
  status: number,
  extraHeaders?: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      ...extraHeaders,
    },
  })
}
