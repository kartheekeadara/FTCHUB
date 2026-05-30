// Supabase Edge Function: self-service auth user deletion
// OWASP: rate limits (IP + user), strict Zod validation, no extra fields in body

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import {
  corsHeaders,
  enforceRateLimit,
  enforceUserRateLimit,
  jsonResponse,
} from "../_shared/rateLimit.ts"
import { parseDeleteAuthUserBody } from "../_shared/validation.ts"

const ENDPOINT = "delete-auth-user"
// Defaults: 20 req / 5 min per IP, 5 req / 5 min per authenticated user
const IP_MAX = 20
const IP_WINDOW = 300
const USER_MAX = 5
const USER_WINDOW = 300

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405)
  }

  // IP rate limit before parsing body
  const ipLimited = await enforceRateLimit(req, {
    endpoint: ENDPOINT,
    ipMax: IP_MAX,
    ipWindowSeconds: IP_WINDOW,
  })
  if (ipLimited) return ipLimited

  const parsed = await parseDeleteAuthUserBody(req)
  if ("error" in parsed) return parsed.error
  const { userId } = parsed.data

  const supabaseAdmin = createClient(
    Deno.env.get("PROJECT_URL") ?? "",
    Deno.env.get("SERVICE_ROLE_KEY") ?? "",
    {
      auth: { autoRefreshToken: false, persistSession: false },
    },
  )

  const authHeader = req.headers.get("Authorization")
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Unauthorized" }, 401)
  }

  const token = authHeader.replace("Bearer ", "")
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(
    token,
  )

  if (authError || !user) {
    return jsonResponse({ error: "Invalid authentication token" }, 401)
  }

  // Per-user rate limit after authentication (IP already counted above)
  const userLimited = await enforceUserRateLimit(
    req,
    {
      endpoint: ENDPOINT,
      ipMax: IP_MAX,
      ipWindowSeconds: IP_WINDOW,
      userMax: USER_MAX,
      userWindowSeconds: USER_WINDOW,
    },
    user.id,
  )
  if (userLimited) return userLimited

  if (user.id !== userId) {
    return jsonResponse({ error: "You can only delete your own account" }, 403)
  }

  const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
    userId,
  )

  if (deleteError) {
    console.error("delete_user_error", deleteError.message)
    return jsonResponse({ error: "Failed to delete user" }, 500)
  }

  return jsonResponse({ success: true, message: "User deleted successfully" }, 200)
})
